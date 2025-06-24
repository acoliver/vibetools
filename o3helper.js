#!/usr/bin/env node

/**
 * O3 Helper - A general-purpose script for consulting OpenAI models with tool support
 * 
 * Usage:
 *   o3helper.js --prompt "Your question here"
 *   o3helper.js --prompt "Explain this code" --file path/to/file.js
 *   o3helper.js --prompt "Help with this" --file file1.js --file file2.ts
 *   o3helper.js --model gpt-4-turbo --prompt "Use a different model"
 *   o3helper.js --system "You are an expert in..." --prompt "Question"
 *   o3helper.js --tools --prompt "Find and analyze code" (enables all file tools)
 *   
 * Environment:
 *   Reads API key from ~/.openai_key
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const os = require('os');
const { execSync } = require('child_process');
const crypto = require('crypto');

// Load configuration
let config = {};
try {
  const configPath = path.join(__dirname, 'o3helper-config.json');
  if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  }
} catch (e) {
  console.error('Warning: Could not load config file:', e.message);
}

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    prompt: null,
    files: [],
    model: 'o3', // Default to o3
    system: `You are a helpful AI assistant with deep expertise in software engineering.

When working with files:
- Feel free to use the current working directory (.) for new files unless the user specifies otherwise
- You can use list_directory to explore the file structure and see what files exist
- When creating files, consider organizing them in subdirectories like 'tmp/', 'output/', or 'examples/' if that makes sense
- Always respect the user's explicit path requests`,
    temperature: 0.7,
    maxTokens: 4096,
    tools: false,
    baseDir: process.cwd()
  };
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--prompt':
      case '-p':
        options.prompt = args[++i];
        break;
      case '--file':
      case '-f':
        options.files.push(args[++i]);
        break;
      case '--model':
      case '-m':
        options.model = args[++i];
        break;
      case '--system':
      case '-s':
        options.system = args[++i];
        break;
      case '--temperature':
      case '-t':
        options.temperature = parseFloat(args[++i]);
        break;
      case '--max-tokens':
        options.maxTokens = parseInt(args[++i]);
        break;
      case '--tools':
        options.tools = true;
        break;
      case '--base-dir':
        options.baseDir = path.resolve(args[++i]);
        break;
      case '--help':
      case '-h':
        showHelp();
        process.exit(0);
    }
  }
  
  if (!options.prompt) {
    if (args.length === 0) {
      // No arguments at all - just show help
      showHelp();
      process.exit(0);
    } else {
      // Arguments provided but no prompt - show error and help
      console.error('Error: --prompt is required\n');
      showHelp();
      process.exit(1);
    }
  }
  
  return options;
}

// Logging functionality
function getClaudeInstanceId() {
  // Try to detect Claude instance from environment or process
  const possibleIds = [
    process.env.CLAUDE_SESSION_ID,
    process.env.CLAUDE_INSTANCE_ID,
    process.env.USER, // fallback to username
    process.ppid, // parent process ID might indicate different Claude sessions
  ].filter(Boolean);
  
  // Create a hash from available identifiers
  const idString = possibleIds.join('-');
  return crypto.createHash('md5').update(idString).digest('hex').substring(0, 8);
}

function detectInvocationSource() {
  // Check if we're being run by Claude Code
  // Claude typically runs commands through bash with specific patterns
  const ppid = process.ppid;
  const parentCmd = process.env._;
  
  // Check for common Claude Code indicators
  if (parentCmd && parentCmd.includes('bash')) {
    // Look for nohup in the process tree (indicates background execution)
    try {
      const psOutput = execSync(`ps -p ${ppid} -o comm=`, { encoding: 'utf8' }).trim();
      if (psOutput.includes('bash') || psOutput.includes('sh')) {
        return 'claude-code';
      }
    } catch (e) {
      // ps command failed, continue with other checks
    }
  }
  
  // Check if running in a typical Claude Code environment
  if (process.cwd().includes('/Users/') && process.env.USER) {
    // Additional heuristic: Claude often runs from specific directories
    return 'likely-claude';
  }
  
  return 'direct-cli';
}

function logVerbose(type, data) {
  if (!config.logging?.verbose?.enabled) return;
  
  try {
    const logDir = path.join(__dirname, 'logs');
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    
    const now = new Date();
    let logFile = config.logging.verbose.logFile || 'logs/o3-verbose.log';
    
    // Handle daily rotation
    if (config.logging.verbose.rotateDaily) {
      const dateStr = now.toISOString().split('T')[0];
      logFile = logFile.replace('.log', `-${dateStr}.log`);
    }
    
    const fullPath = path.join(__dirname, logFile);
    
    // Check size limit
    if (config.logging.verbose.maxLogSizeMB && fs.existsSync(fullPath)) {
      const stats = fs.statSync(fullPath);
      const sizeMB = stats.size / (1024 * 1024);
      if (sizeMB > config.logging.verbose.maxLogSizeMB) {
        // Rotate the log
        fs.renameSync(fullPath, fullPath + '.old');
      }
    }
    
    const logEntry = {
      timestamp: now.toISOString(),
      type: type,
      claude_instance: getClaudeInstanceId(),
      data: data
    };
    
    fs.appendFileSync(fullPath, JSON.stringify(logEntry) + '\n');
  } catch (e) {
    // Don't let verbose logging errors break the flow
  }
}

function logInvocation(options, response, error = null) {
  try {
    const logDir = path.join(__dirname, 'logs');
    
    // Ensure log directory exists
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    
    // Create monthly log file
    const now = new Date();
    const logFile = path.join(logDir, `o3-usage-${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}.log`);
    
    // Prepare log entry
    const logEntry = {
      timestamp: now.toISOString(),
      claude_instance: getClaudeInstanceId(),
      invocation_source: detectInvocationSource(),
      process_info: {
        pid: process.pid,
        ppid: process.ppid,
        cwd: process.cwd(),
        user: os.userInfo().username,
        hostname: os.hostname()
      },
      request: {
        model: options.model,
        prompt: options.prompt.substring(0, 200) + (options.prompt.length > 200 ? '...' : ''),
        prompt_length: options.prompt.length,
        has_tools: options.tools,
        file_count: options.files.length,
        files: options.files,
        base_dir: options.baseDir
      },
      response: error ? null : {
        usage: response?.usage || null,
        tool_calls: response?.choices?.[0]?.message?.tool_calls?.length || 0
      },
      error: error ? error.message : null,
      execution_time_ms: null // Will be set by the caller
    };
    
    // Append to log file
    fs.appendFileSync(logFile, JSON.stringify(logEntry) + '\n');
    
    return logEntry;
  } catch (logError) {
    // Don't let logging errors break the main flow
    console.error('Logging error:', logError.message);
  }
}

function showHelp() {
  console.log(`
O3 Helper - Consult OpenAI models from the command line

Usage:
  o3helper.js --prompt "Your question here"
  o3helper.js --prompt "Explain this code" --file path/to/file.js
  o3helper.js --prompt "Help with this" --file file1.js --file file2.ts
  o3helper.js --model gpt-4-turbo --prompt "Use a different model"
  o3helper.js --system "You are an expert in..." --prompt "Question"

Options:
  -p, --prompt <text>      The prompt/question to send (required)
  -f, --file <path>        Include file contents (can be used multiple times)
  -m, --model <name>       OpenAI model to use (default: o3)
  -s, --system <text>      System prompt (default: helpful AI assistant)
  -t, --temperature <num>  Temperature 0-2 (default: 0.7)
  --max-tokens <num>       Max response tokens (default: 4096)
  --tools                  Enable tool use (read_file, list_directory, grep, edit_file, create_file)
  --base-dir <path>        Base directory for file operations (default: current dir)
  -h, --help              Show this help message

Models:
  o3-mini              O3 Mini (recommended for complex reasoning)
  gpt-4-turbo         GPT-4 Turbo
  gpt-4               GPT-4
  gpt-3.5-turbo       GPT-3.5 Turbo

Environment:
  API key is read from ~/.openai_key
`);
}

// Read API key
function getApiKey() {
  const keyPath = path.join(os.homedir(), '.openai_key');
  try {
    return fs.readFileSync(keyPath, 'utf8').trim();
  } catch (error) {
    console.error(`Error: Could not read API key from ${keyPath}`);
    console.error('Please ensure ~/.openai_key contains your OpenAI API key');
    process.exit(1);
  }
}

// Read file contents
function readFiles(filePaths) {
  const fileContents = [];
  for (const filePath of filePaths) {
    try {
      const absolutePath = path.resolve(filePath);
      const content = fs.readFileSync(absolutePath, 'utf8');
      const ext = path.extname(filePath).slice(1) || 'txt';
      fileContents.push({
        path: filePath,
        content: content,
        language: ext
      });
    } catch (error) {
      console.error(`Warning: Could not read file ${filePath}: ${error.message}`);
    }
  }
  return fileContents;
}

// Build the user message with file contents
function buildUserMessage(prompt, fileContents) {
  if (fileContents.length === 0) {
    return prompt;
  }
  
  let message = prompt + '\n\n';
  
  for (const file of fileContents) {
    message += `--- File: ${file.path} ---\n`;
    message += '```' + file.language + '\n';
    message += file.content;
    message += '\n```\n\n';
  }
  
  return message.trim();
}

// Tool definitions
function getToolDefinitions() {
  // Includes built-in tools plus execute_command which performs shell commands with permission checks
  return [
    {
      type: 'function',
      function: {
        name: 'read_file',
        description: 'Read the contents of a file relative to the base directory',
        parameters: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'The file path relative to the base directory'
            }
          },
          required: ['path']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'execute_command',
        description: 'Execute a shell command with permissions enforced by .o3helper-permissions.json',
        parameters: {
          type: 'object',
          properties: {
            command: {
              type: 'string',
              description: 'The shell command to execute'
            }
          },
          required: ['command']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'list_directory',
        description: 'List files and directories in a given path',
        parameters: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'The directory path to list (relative to base directory)',
              default: '.'
            },
            include_hidden: {
              type: 'boolean',
              description: 'Include hidden files (starting with .)',
              default: false
            }
          },
          required: []
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'grep',
        description: 'Search for a pattern in files using ripgrep',
        parameters: {
          type: 'object',
          properties: {
            pattern: {
              type: 'string',
              description: 'The search pattern (regex supported)'
            },
            path: {
              type: 'string',
              description: 'The directory or file to search in (relative to base directory)',
              default: '.'
            },
            file_type: {
              type: 'string',
              description: 'Filter by file type (e.g., "js", "ts", "py")'
            }
          },
          required: ['pattern']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'create_file',
        description: 'Create a new file with given contents (will not overwrite existing files)',
        parameters: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'The file path relative to the base directory'
            },
            content: {
              type: 'string',
              description: 'The full contents to write to the new file (max 100KB)'
            }
          },
          required: ['path', 'content']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'edit_file',
        description: 'Edit a file by replacing text. Finds exact text match and replaces it.',
        parameters: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'The file path relative to the base directory'
            },
            search_text: {
              type: 'string',
              description: 'The exact text to search for (must match exactly including whitespace)'
            },
            replacement_text: {
              type: 'string',
              description: 'The text to replace it with'
            },
            replace_all: {
              type: 'boolean',
              description: 'Replace all occurrences instead of just the first one',
              default: false
            },
            dry_run: {
              type: 'boolean',
              description: 'If true, perform no write – just return the would-be changes',
              default: false
            }
          },
          required: ['path', 'search_text', 'replacement_text']
        }
      }
    }
  ];
}

// Helper: securely resolve a path and ensure it is within baseDir (guards against symlinks and prefix attacks)
function resolveInsideBase(baseDir, targetPath) {
  const resolvedBase = fs.realpathSync(path.resolve(baseDir));
  const resolvedTarget = fs.realpathSync(path.resolve(baseDir, targetPath));
  // Ensure trailing separator when doing prefix check so "/tmp/base" does not match "/tmp/baseevil"
  const baseWithSep = resolvedBase.endsWith(path.sep) ? resolvedBase : resolvedBase + path.sep;
  if (!resolvedTarget.startsWith(baseWithSep)) {
    throw new Error('Access denied: Path is outside base directory');
  }
  return resolvedTarget;
}

// Execute tool calls
async function executeToolCall(toolCall, baseDir) {
  const { name, arguments: args } = toolCall.function;
  // The OpenAI API may return `arguments` either as a JSON string *or* as an
  // already-parsed object depending on the SDK / transport.  Accept both to
  // make the helper more robust.
  let parsedArgs;
  if (typeof args === 'string') {
    try {
      parsedArgs = JSON.parse(args);
    } catch (err) {
      // If we cannot parse, surface a clear error back to the model.
      return { error: `Failed to parse tool arguments: ${err.message}` };
    }
  } else if (typeof args === 'object' && args !== null) {
    parsedArgs = args;
  } else {
    return { error: 'Invalid tool arguments format' };
  }
  
  try {
    switch (name) {
      case 'read_file': {
        let filePath;
        try {
          // Security: resolve and ensure inside base
          filePath = resolveInsideBase(baseDir, parsedArgs.path);
        } catch (err) {
          return { error: err.message };
        }
        try {
          let content = fs.readFileSync(filePath, 'utf8');
          let truncated = false;
          const MAX_CHARS = 32000; // prevent gigantic payloads
          if (content.length > MAX_CHARS) {
            content = content.slice(0, MAX_CHARS) + '\n...[truncated]';
            truncated = true;
          }
          return { path: parsedArgs.path, content, truncated };
        } catch (error) {
          return { error: `Failed to read file: ${error.message}` };
        }
      }
      
      case 'list_directory': {
        const dirPath = parsedArgs.path || '.';
        let resolvedPath;
        try {
          resolvedPath = resolveInsideBase(baseDir, dirPath);
        } catch (err) {
          return { error: err.message };
        }
        
        try {
          const entries = fs.readdirSync(resolvedPath, { withFileTypes: true });
          const includeHidden = parsedArgs.include_hidden || false;
          
          const result = {
            path: dirPath,
            directories: [],
            files: []
          };
          
          for (const entry of entries) {
            if (!includeHidden && entry.name.startsWith('.')) continue;
            
            if (entry.isDirectory()) {
              result.directories.push(entry.name);
            } else if (entry.isFile()) {
              result.files.push(entry.name);
            }
          }
          
          // Sort for consistent output
          result.directories.sort();
          result.files.sort();
          
          return result;
        } catch (error) {
          return { error: `Failed to list directory: ${error.message}` };
        }
      }
      
      case 'grep': {
        let searchPath;
        try {
          searchPath = resolveInsideBase(baseDir, parsedArgs.path || '.');
        } catch (err) {
          return { error: err.message };
        }
        try {
          // Build ripgrep command
          let cmd = `rg --json "${parsedArgs.pattern.replace(/"/g, '\\"')}" "${searchPath}"`;
          if (parsedArgs.file_type) {
            cmd += ` -t ${parsedArgs.file_type}`;
          }
          
          const output = execSync(cmd, { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
          const lines = output.split('\n').filter(line => line.trim());
          const matches = [];
          
          for (const line of lines) {
            try {
              const json = JSON.parse(line);
              if (json.type === 'match') {
                matches.push({
                  path: json.data.path.text,
                  line_number: json.data.line_number,
                  lines: json.data.lines.text,
                  submatches: json.data.submatches
                });
              }
            } catch {
              // Ignore non-JSON lines
            }
          }
          
          return { matches: matches.slice(0, 50) }; // Limit results
        } catch (error) {
          if (error.status === 1) {
            return { matches: [] }; // No matches found
          }
          return { error: `Grep failed: ${error.message}` };
        }
      }
      
      case 'execute_command': {
        if (!parsedArgs.command || typeof parsedArgs.command !== 'string') {
          return { error: "Invalid parameter: 'command' must be a non-empty string" };
        }
        const permissionsPath = path.resolve(baseDir, '.o3helper-permissions.json');
        let perms;
        try {
          const jsonStr = fs.readFileSync(permissionsPath, 'utf8');
          perms = JSON.parse(jsonStr);
        } catch (err) {
          return { error: `Failed to read permissions file: ${err.message}` };
        }

        const rules = perms.rules || [];
        const defPolicy = perms.default || 'ask';
        const pending = perms.pending_approvals || {};

        const cmd = parsedArgs.command.trim();
        let decision = { permission: defPolicy, rule: null };
        for (const rule of rules) {
          try {
            const regex = new RegExp(rule.pattern);
            if (regex.test(cmd)) {
              decision = { permission: rule.permission, rule };
              break;
            }
          } catch (e) {
            // Ignore invalid regexes
          }
        }

        if (decision.permission === 'never') {
          return { error: 'Permission denied' };
        }

        if (decision.permission === 'ask') {
          if (!pending[cmd]) {
            // Add to pending approvals and persist
            pending[cmd] = { approved: false, requested_at: Date.now(), rule: decision.rule };
            try {
              fs.writeFileSync(permissionsPath, JSON.stringify({ ...perms, pending_approvals: pending }, null, 2));
            } catch (e) {
              // ignore write errors
            }
            return { error: 'Permission requires approval and has been added to pending_approvals' };
          }
          if (!pending[cmd].approved) {
            return { error: 'Permission pending approval' };
          }
          // approved => allow
        }

        try {
          const execOutput = execSync(cmd, {
            encoding: 'utf8',
            maxBuffer: 5 * 1024 * 1024 // 5MB buffer; we'll slice below
          });
          // Handle large outputs intelligently
          let output = execOutput;

          // --- 1. Check size thresholds (both line- and char-based) ---
          const lines = output.split('\n');
          const totalLines = lines.length;
          const totalChars = output.length;

          // These thresholds were tuned for typical OpenAI context limits.
          const MAX_LINES = 120;        // previous value: 100
          const MAX_CHARS = 30_000;     // new char-based safeguard
          const HEAD_LINES = 40;        // show a bit more context at the top
          const TAIL_LINES = 40;        // and bottom – total preview <= 80 lines

          const exceedsLineLimit = totalLines > MAX_LINES;
          const exceedsCharLimit = totalChars > MAX_CHARS;

          if (exceedsLineLimit || exceedsCharLimit) {
            // --- 2. Persist full output so it can be inspected with read_file ---
            let relativeLogPath;
            try {
              const tmpDir = path.join(baseDir, 'tmp');
              fs.mkdirSync(tmpDir, { recursive: true });
              const fileName =
                'exec-' +
                Date.now().toString() +
                '-' +
                Math.random().toString(36).slice(2, 8) +
                '.log';
              relativeLogPath = path.join('tmp', fileName); // relative to baseDir
              const absLogPath = path.join(baseDir, relativeLogPath);
              fs.writeFileSync(absLogPath, output, 'utf8');
            } catch (err) {
              // If persisting fails, fall back gracefully – we'll just not provide a path
              relativeLogPath = null;
            }

            // --- 3. Build truncated preview ---
            const head = lines.slice(0, HEAD_LINES).join('\n');
            const tail = lines.slice(-TAIL_LINES).join('\n');
            const skippedLines = Math.max(0, totalLines - HEAD_LINES - TAIL_LINES);
            const preview =
              `${head}\n\n` +
              `... [Output truncated: showing first ${HEAD_LINES} and last ${TAIL_LINES} ` +
              `of ${totalLines} total lines (${totalChars.toLocaleString()} chars)]\n` +
              (skippedLines > 0 ? `... [Skipped ${skippedLines} lines]\n\n` : '\n') +
              `${tail}`;

            // --- 4. Craft response object ---
            const response = {
              command: cmd,
              truncated: true,
              totalLines,
              totalChars,
              output: preview,
              suggestion: `Full output saved to ${relativeLogPath ?? 'N/A'}. ` +
                `You can inspect it with read_file or download it later.`
            };
            if (relativeLogPath) response.fullOutputPath = relativeLogPath;
            return response;
          }

          // Small enough – just return as-is
          return { command: cmd, output };
        } catch (e) {
          return { command: cmd, error: e.message, stderr: e.stdout ? undefined : e.stderr };
        }
      }

      case 'create_file': {
        if (!parsedArgs.path || typeof parsedArgs.path !== 'string') {
          return { error: "Invalid parameter: 'path' must be a non-empty string" };
        }
        if (typeof parsedArgs.content !== 'string') {
          return { error: "Invalid parameter: 'content' must be a string" };
        }

        // Size limit 100KB
        const MAX_BYTES = 100 * 1024;
        const contentBytes = Buffer.byteLength(parsedArgs.content, 'utf8');
        if (contentBytes > MAX_BYTES) {
          return { error: `Content exceeds size limit of ${MAX_BYTES} bytes` };
        }

        // For create_file, we can't use resolveInsideBase since the file doesn't exist yet
        // Instead, resolve the parent directory and check that
        const targetPath = path.resolve(baseDir, parsedArgs.path);
        const targetDir = path.dirname(targetPath);
        
        let filePath;
        try {
          // Check if parent directory is inside base
          const resolvedBase = fs.realpathSync(path.resolve(baseDir));
          const baseWithSep = resolvedBase.endsWith(path.sep) ? resolvedBase : resolvedBase + path.sep;
          
          // If parent exists, check it's inside base
          if (fs.existsSync(targetDir)) {
            const resolvedParent = fs.realpathSync(targetDir);
            if (!resolvedParent.startsWith(baseWithSep)) {
              return { error: 'Access denied: Path is outside base directory' };
            }
          } else {
            // Parent doesn't exist - check the path string itself
            const normalizedTarget = path.resolve(targetPath);
            if (!normalizedTarget.startsWith(baseWithSep)) {
              return { error: 'Access denied: Path is outside base directory' };
            }
          }
          filePath = targetPath;
        } catch (err) {
          return { error: `Security check failed: ${err.message}` };
        }

        if (fs.existsSync(filePath)) {
          return { error: 'File already exists – refusing to overwrite' };
        }

        try {
          // Ensure parent directories exist
          const dir = path.dirname(filePath);
          fs.mkdirSync(dir, { recursive: true });
          // Write file with exclusive flag to avoid race conditions
          fs.writeFileSync(filePath, parsedArgs.content, { encoding: 'utf8', flag: 'wx' });
          return { success: true, message: `File created at ${parsedArgs.path}` };
        } catch (error) {
          return { error: `Failed to create file: ${error.message}` };
        }
      }


      case 'edit_file': {
        // --------------------------
        // 1. Validate input params
        // --------------------------
        if (!parsedArgs.path || typeof parsedArgs.path !== 'string') {
          return { error: "Invalid parameter: 'path' must be a non-empty string" };
        }
        if (!parsedArgs.search_text || typeof parsedArgs.search_text !== 'string') {
          return { error: "Invalid parameter: 'search_text' must be a non-empty string" };
        }
        if (typeof parsedArgs.replacement_text !== 'string') {
          return { error: "Invalid parameter: 'replacement_text' must be a string" };
        }

        let filePath;
        try {
          filePath = resolveInsideBase(baseDir, parsedArgs.path);
        } catch (err) {
          return { error: err.message };
        }

        try {
          // --------------------------
          // 2. Read file & detect EOL
          // --------------------------
          const MAX_FILE_BYTES = 1_000_000; // 1 MB safety limit
          const stats = fs.statSync(filePath);
          if (stats.size > MAX_FILE_BYTES) {
            return { error: `Refusing to edit files larger than ${MAX_FILE_BYTES} bytes for safety (file is ${stats.size} bytes)` };
          }
          const originalContent = fs.readFileSync(filePath, 'utf8');

          if (originalContent.length === 0) {
            return { error: 'File is empty – nothing to replace' };
          }

          // Detect dominant newline style (LF or CRLF) so that we can
          // normalise during search but preserve on write.
          const hasCRLF = /\r\n/.test(originalContent);
          const toLF = (str) => str.replace(/\r\n/g, '\n');
          const fromLF = (str) => (hasCRLF ? str.replace(/\n/g, '\r\n') : str);

          const normalisedContent = toLF(originalContent);
          const normalisedSearch = toLF(parsedArgs.search_text);
          const normalisedReplacement = toLF(parsedArgs.replacement_text);

          // --------------------------
          // 3. Perform replacement
          // --------------------------
          let updatedContentLF;
          let replacementCount = 0;

          const isDryRun = !!parsedArgs.dry_run;

          if (parsedArgs.replace_all) {
            // Replace all literal occurrences.  Build a global RegExp that
            // escapes special characters so the search is treated literally.
            const regex = new RegExp(normalisedSearch.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), 'g');
            updatedContentLF = normalisedContent.replace(regex, () => {
              replacementCount++;
              return normalisedReplacement;
            });
          } else {
            const idx = normalisedContent.indexOf(normalisedSearch);
            if (idx === -1) {
              // Provide helpful context about why the search failed
              const searchLines = normalisedSearch.split('\n');
              const firstLine = searchLines[0];
              const firstLineIdx = normalisedContent.indexOf(firstLine);
              
              let errorMsg = 'Search text not found in file';
              if (firstLineIdx !== -1) {
                // First line exists, might be a multi-line mismatch
                errorMsg += '. The first line of your search was found, but the full multi-line text did not match exactly.';
                
                // Show a preview of what was found
                const contextStart = Math.max(0, firstLineIdx - 50);
                const contextEnd = Math.min(normalisedContent.length, firstLineIdx + firstLine.length + 200);
                const context = normalisedContent.slice(contextStart, contextEnd);
                errorMsg += ` Found context: ...${context.replace(/\n/g, '\\n')}...`;
              }
              
              return { error: errorMsg };
            }
            replacementCount = 1;
            updatedContentLF =
              normalisedContent.slice(0, idx) +
              normalisedReplacement +
              normalisedContent.slice(idx + normalisedSearch.length);
          }

          if (replacementCount === 0) {
            return { error: 'Search text not found in file' };
          }

          // --------------------------
          // 4. Prepare final content & backup
          // --------------------------
          const updatedContent = fromLF(updatedContentLF);

          if (isDryRun) {
            return {
              success: true,
              dry_run: true,
              message: `Would replace ${replacementCount} occurrence(s) in ${parsedArgs.path}`,
              path: parsedArgs.path,
              replacements: replacementCount,
              preview: updatedContent.slice(0, 1000) // first 1k chars for preview
            };
          }

          // Create a timestamped backup before writing, just in case.
          const backupPath = `${filePath}.bak-${Date.now()}`;
          fs.copyFileSync(filePath, backupPath);

          // Write atomically: write temp then rename to reduce corruption risk
          const tmpPath = `${filePath}.tmp-${process.pid}`;
          fs.writeFileSync(tmpPath, updatedContent, 'utf8');
          fs.renameSync(tmpPath, filePath);

          return {
            success: true,
            message: `Replaced ${replacementCount} occurrence(s) in ${parsedArgs.path}. Backup created at ${path.basename(backupPath)}`,
            path: parsedArgs.path,
            replacements: replacementCount,
            backup: path.basename(backupPath)
          };
        } catch (error) {
          return { error: `Failed to edit file: ${error.message}` };
        }
      }
      
      default:
        return { error: `Unknown tool: ${name}` };
    }
  } catch (error) {
    return { error: error.message };
  }
}

// Make API request to OpenAI
async function callOpenAI(apiKey, options, userMessage) {
  // Use max_completion_tokens for o3 models, max_tokens for others
  const tokenParam = options.model.startsWith('o3') ? 'max_completion_tokens' : 'max_tokens';
  
  // Build request data - o3 models don't support temperature
  const messages = [
    { role: 'system', content: options.system },
    { role: 'user', content: userMessage }
  ];
  
  const requestBody = {
    model: options.model,
    messages: messages,
    [tokenParam]: options.maxTokens
  };
  
  // Add tools if enabled
  if (options.tools) {
    requestBody.tools = getToolDefinitions();
  }
  
  // Only add temperature for non-o3 models
  if (!options.model.startsWith('o3')) {
    requestBody.temperature = options.temperature;
  }
  
  return makeOpenAIRequest(apiKey, requestBody, options);
}

// Make the actual API request (separated for recursion with tool calls)
async function makeOpenAIRequest(apiKey, requestBody, options) {
  const requestData = JSON.stringify(requestBody);
  
  const requestOptions = {
    hostname: 'api.openai.com',
    port: 443,
    path: '/v1/chat/completions',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'Content-Length': Buffer.byteLength(requestData)
    }
  };
  
  return new Promise((resolve, reject) => {
    const req = https.request(requestOptions, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', async () => {
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data);
            
            // Check if the response contains tool calls
            if (response.choices?.[0]?.message?.tool_calls && options.tools) {
              const toolCalls = response.choices[0].message.tool_calls;
              console.log('\n---TOOL CALLS---');
              
              // Execute each tool call
              const toolResults = [];
              for (const toolCall of toolCalls) {
                console.log(`Executing ${toolCall.function.name}...`);
                
                // Verbose logging - tool calls
                if (config.logging?.verbose?.enabled && config.logging.verbose.includeToolCalls) {
                  logVerbose('tool_call', {
                    tool: toolCall.function.name,
                    arguments: toolCall.function.arguments
                  });
                }
                
                const result = await executeToolCall(toolCall, options.baseDir);
                
                // Verbose logging - tool results
                if (config.logging?.verbose?.enabled && config.logging.verbose.includeToolCalls) {
                  logVerbose('tool_result', {
                    tool: toolCall.function.name,
                    result: result
                  });
                }
                
                toolResults.push({
                  tool_call_id: toolCall.id,
                  role: 'tool',
                  content: JSON.stringify(result)
                });
              }
              
              // Add the assistant's message with tool calls to the conversation
              requestBody.messages.push({
                role: 'assistant',
                content: response.choices[0].message.content || null,
                tool_calls: toolCalls
              });
              
              // Add tool results to the conversation
              requestBody.messages.push(...toolResults);
              
              // Make another request to get the final response
              console.log('\n---PROCESSING TOOL RESULTS---');
              const finalResponse = await makeOpenAIRequest(apiKey, requestBody, options);
              resolve(finalResponse);
            } else {
              resolve(response);
            }
          } catch (error) {
            reject(new Error(`Failed to parse response: ${error.message}`));
          }
        } else {
          reject(new Error(`API request failed with status ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    req.write(requestData);
    req.end();
  });
}

// Main function
async function main() {
  const startTime = Date.now();
  const options = parseArgs();
  const apiKey = getApiKey();
  
  // Read any specified files
  const fileContents = readFiles(options.files);
  
  // Build the complete user message
  const userMessage = buildUserMessage(options.prompt, fileContents);
  
  // Verbose logging - request details
  if (config.logging?.verbose?.enabled && config.logging.verbose.includeFullPrompt) {
    logVerbose('request', {
      model: options.model,
      prompt: options.prompt, // Full prompt
      files: fileContents,
      system: options.system,
      tools: options.tools,
      baseDir: options.baseDir
    });
  }
  
  // Show what we're sending
  console.log(`\n🤖 Consulting ${options.model}...`);
  if (fileContents.length > 0) {
    console.log(`📎 Including ${fileContents.length} file(s)`);
  }
  if (options.tools) {
    console.log(`🔧 Tools enabled: read_file, list_directory, grep, edit_file, create_file, execute_command`);
    console.log(`📁 Base directory: ${options.baseDir}`);
  }
  console.log('\n---REQUEST---');
  console.log(`Model: ${options.model}`);
  if (!options.model.startsWith('o3')) {
    console.log(`Temperature: ${options.temperature}`);
  }
  console.log(`System: ${options.system.substring(0, 100)}...`);
  console.log(`\nPrompt: ${options.prompt}`);
  if (fileContents.length > 0) {
    console.log(`Files: ${fileContents.map(f => f.path).join(', ')}`);
  }
  console.log('\n---RESPONSE---\n');
  
  try {
    const response = await callOpenAI(apiKey, options, userMessage);
    
    // Log successful invocation
    const logEntry = logInvocation(options, response);
    if (logEntry) {
      logEntry.execution_time_ms = Date.now() - startTime;
      // Update the log entry with execution time
      const logDir = path.join(__dirname, 'logs');
      const now = new Date();
      const logFile = path.join(logDir, `o3-usage-${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}.log`);
      const logs = fs.readFileSync(logFile, 'utf8').trim().split('\n');
      logs[logs.length - 1] = JSON.stringify({...JSON.parse(logs[logs.length - 1]), execution_time_ms: logEntry.execution_time_ms});
      fs.writeFileSync(logFile, logs.join('\n') + '\n');
    }
    
    if (response.choices && response.choices.length > 0) {
      const content = response.choices[0].message.content;
      console.log(content);
      
      // Verbose logging - full response
      if (config.logging?.verbose?.enabled && config.logging.verbose.includeFullResponse) {
        logVerbose('response', {
          content: content,
          usage: response.usage,
          model: response.model,
          finish_reason: response.choices[0].finish_reason
        });
      }
      
      // Also log token usage
      if (response.usage) {
        console.log('\n---USAGE---');
        console.log(`Prompt tokens: ${response.usage.prompt_tokens}`);
        console.log(`Completion tokens: ${response.usage.completion_tokens}`);
        console.log(`Total tokens: ${response.usage.total_tokens}`);
      }
    } else {
      console.error('Error: No response from API');
    }
  } catch (error) {
    // Log failed invocation
    logInvocation(options, null, error);
    console.error(`\n❌ Error: ${error.message}`);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  main().catch(error => {
    console.error(`\n❌ Unexpected error: ${error.message}`);
    process.exit(1);
  });
}

module.exports = { callOpenAI, buildUserMessage, executeToolCall };
