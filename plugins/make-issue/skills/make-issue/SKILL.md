---
name: make-issue
description: Create a new GitHub issue based on the $ARGUMENTS input from the user.
disable-model-invocation: true
argument-hint: "[issue description]"
---

Create a new GitHub issue based on the $ARGUMENTS input from the user.

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
- Fetch all available labels:
  ```bash
  gh label list --limit 100 --json name,description,color
  ```
  If the repository has more than 100 labels, increase the limit or paginate.

### 2. Template selection

If issue templates are available, use `AskUserQuestion` to ask which template to use.

### 3. Issue type selection

If issue types are available, use `AskUserQuestion` to let the user select one.

### 4. Label selection

Analyze the issue content and auto-suggest relevant labels:
- Group labels by category/prefix (e.g., "type:", "priority:", "area:", "status:")
- For each category, use `AskUserQuestion` with multiSelect enabled
- Show your auto-suggested labels and indicate which ones you recommend
- Cover all available labels across multiple questions if needed

### 5. Write the issue

Write the issue concise and to the point but with enough working information and context.

### 6. Create the issue

Create the issue in a single request with all selected labels.

**With issue type:**
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

**Without issue type:**
```bash
gh issue create --title '{title}' --body '{body}' --label 'label1,label2'
```

### 7. Provide link

Provide a link to the newly created issue.
