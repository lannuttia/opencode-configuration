---
description: Start a TDD session from a Jira ticket's acceptance criteria
agent: tdd
---

You are starting a TDD session driven by a Jira ticket.

## Step 1: Fetch the Jira ticket

Fetch the full details of Jira ticket **$1** using the Jira MCP tools. Retrieve the
summary, description, and acceptance criteria. If the ticket has subtasks or linked
issues that contain additional acceptance criteria, fetch those too.

## Step 2: Extract acceptance criteria

Parse the ticket and extract a clear list of acceptance criteria or requirements.
If the ticket lacks explicit acceptance criteria, derive testable requirements from
the description. Present the extracted requirements to the user for confirmation
before proceeding.

## Step 3: Map criteria to TDD increments

Convert each acceptance criterion into one or more small, testable increments.
Order them so that each increment builds on the previous one. Present this mapping
to the user for review.

## Step 4: Begin TDD

Once the user confirms the increments:
1. Identify the test framework and test runner for this project
2. Run existing tests to establish a green baseline (if any exist)
3. Create the full todo list with all increments and their 7 gated phases
   (RED write, RED verify, GREEN write, GREEN verify, GREEN commit,
   REFACTOR improve, REFACTOR verify)
4. Begin the first Red-Green-Refactor cycle

## Step 5: Update Jira

After completing all increments, add a comment to the Jira ticket summarizing
what was implemented and which tests were added. Include the list of commits
created during the TDD session.

If additional arguments were provided: $ARGUMENTS
