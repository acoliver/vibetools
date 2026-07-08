# Writing Styleguide

> Coalesced from writing styleguides across several projects and intentionally
> stripped of all domain-, client-, and publication-specific content. What remains
> is a general-purpose styleguide for clear, credible, professional writing —
> usable by humans or AI agents for any non-fiction prose project.

## Voice and tone

Write like a senior practitioner explaining something to a peer. Informed, direct,
specific, occasionally funny — never performative. You know the material. You don't
need rhetorical tricks to prove it.

Think Stripe docs, not McKinsey slides. Narrative prose that earns trust through
specificity, not through adjectives.

### Know your reader

Before writing, know who the reader is and write to them. Not at them, not above
them, not below them. If you have multiple audiences, know which one a given
section is for and write to that person. Don't write to an imaginary executive
when the real reader is an engineer, a PM, or a domain practitioner.

For any sentence, ask: would the intended reader read this and trust that the
author understands their world? If not, cut it.

## Things to stop doing

### Rhetorical pivots

Do not write "That's not X, that's Y" or "X isn't about Y. It's about Z." This is a
crutch. State what the thing is. The reader can figure out what it isn't.

**No:** "This isn't a tooling problem. It's a culture problem."
**Yes:** "The postmortem identified three process gaps, none of which were caused by the toolchain."

### Em dashes

Do not use em dashes. If a sentence needs an em dash to work, rewrite it as two
sentences or use a comma. Parenthetical asides are either important enough to be
their own sentence or unimportant enough to cut.

### The dramatic one-liner kicker

Do not end a paragraph with a short punchy sentence that exists only to sound cool
or land a blow. If the paragraph made the point, stop. Trust it.

**No:** "The demo skips the hard parts."
**No:** "And it shows."
**Yes:** Just end after the substance.

### Breathless escalation

Do not stack adjectives or modifiers to inflate stakes. "Simple and seductive,"
"swift and unforgiving," "painful but necessary." Pick one or describe what
actually happened.

### Fake authority moves

Do not write "here's the thing," "let's be clear," "make no mistake," "to be sure,"
"the reality is," or "read that carefully." These are filler that signal you're
about to say something you think is important. If it's important, the evidence will
make that obvious.

### Listy showoff sentences

Do not stack four or five parallel items in a sentence to demonstrate breadth
unless each item is doing real work. Pick the two that matter most for the specific
point you're making.

### Overselling the stakes

Match the rhetoric to the subject. A calorie-counting app does not need
zero-downtime rolling deploys. Scale the language to the actual example.

### Staccato sentence fragments

Do not write sequences of short subject-verb fragments to create dramatic rhythm.
This is a music video montage, not prose. Combine into a sentence, or pick one.

### Hypothetical sass

Do not write sarcastic hypotheticals like "Go ahead, I'll wait" or "Good luck with
that." It reads like Twitter, not professional writing.

### Telling the reader how to feel

Do not write "that's damning," "this is the case that demonstrates," or "the pattern
is unambiguous." Present the facts. The reader is a professional who can draw
conclusions.

### Bullet soup

Bullets are fine for lists of concrete items (metrics, criteria, steps). But a
section that is *only* bullets with no connecting narrative reads like a slide
deck. Every bullet section needs enough surrounding prose to explain why the list
exists and what to do with it.

**No:**

- Deployment frequency
- Lead time for changes
- Mean time to recovery
- Change failure rate

**Yes:**

The team tracks four DORA metrics, but the one that actually drove improvement was
change failure rate. When that number dropped from 30% to 8%, the weekly rollback
meetings disappeared, and deployment frequency rose on its own.

### Formulaic section headers

Do not use the same template header pattern for every item in a list. If you're
writing twenty items, each one should read as its own brief explanation with enough
narrative to make it useful standalone. The structure can be consistent without
being mechanical.

### Forced product connections

Only connect a product or tool to a concept when the connection is genuine and
specific. If the connection is "indirectly helps" or "could theoretically support,"
don't make it. Writing should be useful to someone who never buys anything. That's
what makes it trustworthy.

## Things to do

### Let facts carry weight

A strong fact doesn't need a strong sentence around it. "Only 3 of 12 services
survived the chaos engineering run." That's enough. Don't add "let that sink in" or
"the implications are staggering."

### Use short sentences after complex ones

When you've just explained something dense, follow it with something plain. This
gives the reader a beat. It also keeps you from stacking clause on clause.

### Be specific over general

"Atlassian reported its first-ever decline in enterprise seat count" is better than
"SaaS companies are seeing pressure on their core metrics." Name names, cite
numbers, link sources.

### Avoid empty adjectives

Do not use adjectives that mean "big," "simple," "important," or "good." Words like
*massive, crucial, critical, key, significant, compelling, straightforward,
elegant, powerful, robust, seamless.* If something is big, the number will show it.
If something is important, the context will show it. If you need an adjective to
convince the reader something matters, the sentence isn't doing its job.

### Be honest about what you don't know

If something is unclear, say so. "It's too early to tell whether revenue will
offset the decline" is a better sentence than constructing a confident prediction.

### Have a point of view without being a blowhard

You can take a position. You should take a position. But support it with evidence
and acknowledge where the counterargument is strong. The reader respects "this
argument has merit but misses X" more than "this argument is dead wrong."

### Give examples, not just definitions

When introducing a concept, don't just define it. Show what it looks like. Walk
through a concrete scenario. Readers don't need to be told that something is
important. They need to know what it looks like in practice.

### Explain motivation before mechanics

Before describing how to measure or build something, explain why someone would need
to. What question are they trying to answer? What happens if they don't have this?
What do they do with the result once they have it?

### Be honest about limitations

If a tool or approach doesn't help with a particular problem, say so — or just
don't mention it. Writing that claims everything benefits from one solution is a
sales pitch. Writing that says "this is a process problem; tooling doesn't change
it" is credible. Credibility is the product.

## Sourcing

### Quotes

Always attribute with the person's name, title, and where they said it. Inline link
to the original source. For PDFs, include page number.

**Example:** The RFC proposes "lazy reconciliation on read" as the default conflict
resolution strategy ([RFC 47](https://example.com), §3.2).

### Claims and data points

Any specific number, statistic, or factual claim needs an inline link to the
source. If you can't find a source, flag it rather than asserting it.

### Don't paraphrase quotes and attribute them

If you're extending or interpreting what someone said, make clear which words are
theirs and which are yours. Don't blend your editorializing into their quote.

**No:** The CTO said they're moving away from microservices.
**Yes:** The CTO [told The Register](https://example.com) the team is "collapsing
12 services into 3" because "the operational overhead ate all our velocity." The
trade-off is fewer deployment boundaries, which means larger blast radius per
failure.

### Use primary sources

Link to primary sources (official publications, press releases, original research)
rather than secondary interpretations. Consulting firm analyses and commentary are
useful for framing but should supplement, not replace, the primary source. The
reader can read the original themselves — give them the link.

### When you're uncertain

Say "according to" or "as reported by" and link it. If you can't verify a claim
from the source material, write `[needs verification]` and move on.

## Structural rules

### Cross-links

If writing for a knowledge center or multi-page resource, every page should link to
at least two other pages. Use natural inline references, not just a list at the
bottom (though a bottom list is fine too).

### Vocabulary consistency

Once you establish vocabulary terms for a project, use them consistently. Don't
drift between synonyms. If you call something "worker" on page 1, don't call it
"agent" on page 5. When you catch yourself reaching for a different word, ask
whether it's actually a different concept — if not, use the established term.

## Review gate

Before any piece is considered complete, re-read it specifically hunting for:

1. Em dashes.
2. "Not just X, but Y" rhetorical pivots.
3. Fake authority moves ("here's the thing," "let's be clear," etc.).
4. Breathless escalation or staccato fragments.
5. Dramatic one-liner kickers at paragraph ends.
6. Bullet soup — sections that are only bullets with no narrative.
7. Empty adjectives doing the work that facts should.
8. Unattributed claims or missing source links.
9. Vocabulary drift — terms used inconsistently.
10. Paragraphs written for the wrong reader.

Each of these costs trust. Trust is the product.