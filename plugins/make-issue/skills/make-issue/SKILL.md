---
name: make-issue
description: Create a new GitHub issue with guided template, type, and label selection. Gathers repo metadata, suggests labels, writes a well-structured issue body, and asks for confirmation before submitting.
disable-model-invocation: true
argument-hint: "[issue description]"
---

Create a new GitHub issue based on the $ARGUMENTS input from the user.

If no arguments were provided, use `AskUserQuestion` to ask what the issue is about before proceeding.

## Procedure

### 1. Gather repository info

Run these commands in parallel to collect all necessary data upfront:

- Check for issue templates in `.github/ISSUE_TEMPLATE/`
- Get repo metadata: `gh repo view --json owner,name,id`
- Fetch available issue types:
  ```bash
  gh api graphql -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        issueTypes(first: 20) {
          nodes {
            id
            name
            description
          }
        }
      }
    }
  ' -f owner='{owner}' -f name='{repo}'
  ```
- Fetch all available labels with their IDs (needed for the GraphQL mutation):
  ```bash
  gh api graphql -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        labels(first: 100) {
          nodes {
            id
            name
            description
            color
          }
        }
      }
    }
  ' -f owner='{owner}' -f name='{repo}'
  ```
  If the repository has more than 100 labels, paginate using `after` cursor.

### 2. Template selection

If issue templates are available, use `AskUserQuestion` to ask which template to use. Use the template to structure the issue body in step 5.

### 3. Issue type selection

If issue types are available, use `AskUserQuestion` to let the user select one.

### 4. Label selection

Analyze the issue content and auto-suggest relevant labels. Keep this efficient — at most 3 rounds of questions:

- **Round 1**: Type and priority labels (e.g., "bug", "feature", "priority: high"). Pre-select the ones you recommend.
- **Round 2**: Area and scope labels (e.g., "area: frontend", "integration: todoist"). Skip if not applicable.
- **Round 3**: Any remaining label categories. Skip if all labels are covered.

Use `AskUserQuestion` with multiSelect enabled for each round. If there are fewer than 5 labels total, handle them in a single round.

### 5. Write the issue

Draft a title and body. The body should be concise but contain enough context to be actionable. Structure depends on the issue type:

**Bug reports** — include:
- What's happening (observed behavior)
- What should happen (expected behavior)
- Steps to reproduce if the user provided them

**Feature requests** — include:
- What the feature should do
- Why it's needed (context from the user's description)

**General issues** — keep it straightforward: describe the problem or task and any relevant context.

If a template was selected in step 2, follow the template's structure.

### 6. Confirm before creating

Use `AskUserQuestion` to show the user the draft:

- **Option 1: "Create issue"** — include the title, labels, and issue type in the description so the user can review everything at a glance
- **Option 2: "Edit"** — let the user provide feedback to adjust the draft

Do not create the issue until the user approves.

### 7. Create the issue

Create the issue in a single request with all selected labels.

**With issue type** (use GraphQL — this is the only way to set issue types):
```bash
gh api graphql -f query='
  mutation($repositoryId: ID!, $title: String!, $body: String!, $issueTypeId: ID!, $labelIds: [ID!]) {
    createIssue(input: {repositoryId: $repositoryId, title: $title, body: $body, issueTypeId: $issueTypeId, labelIds: $labelIds}) {
      issue {
        number
        url
      }
    }
  }
' -f repositoryId='{repoId}' -f title='{title}' -f body='{body}' -f issueTypeId='{selectedIssueTypeId}' -f labelIds='["{labelId1}","{labelId2}"]'
```

**Without issue type** (use the simpler CLI):
```bash
gh issue create --title '{title}' --body '{body}' --label 'label1,label2'
```

### 8. Provide link

Provide the URL to the newly created issue.
