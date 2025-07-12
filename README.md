# vibetools
tools I use for vibe coding.

# o3helper

I created this because Claude Opus and Sonnet (4) can be really bad sometimes. So o3helper let's them call o3. Right now it doesn't do patches very well so I mostly have them call for advice or to explain why something they implemented is bad.

# PLAN.md

This is a semi-agentic human in the loop planning system. Tell the LLM what you want then tell it to use @PLAN.md to create a plan in wherever/nameofplan-p1/. Then in a clean context do each "task" individually and use the "a" version of the task to verify. This produces better results on average than not doing this.
