# Commit Message Rules

Every commit in this repository must follow the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification. This applies to every team member and every commit, including documentation-only changes.

The rules are checked automatically in two places:

- **Locally**, by the `commit-msg` hook in `.githooks/`, once you enable it (see [One-time setup](#one-time-setup)).
- **On GitHub**, by the `Commit messages` workflow, which checks every commit pushed to `main` and every commit in a pull request.

## One-time setup

Run these commands once, from the repository root, after you clone:

```sh
git config core.hooksPath .githooks
git config commit.template .gitmessage
```

The first command turns on the local check, so Git rejects a bad message before the commit is created. The second command pre-fills your editor with a reminder of the format when you run `git commit` without `-m`.

On macOS or Linux, also make sure the hook is executable:

```sh
chmod +x .githooks/commit-msg
```

## Message structure

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

1. The first line is the **header**. It starts with a type, an optional scope in parentheses, an optional `!`, then a colon and one space, then a short description.
2. If there is a body, it starts after **one blank line** below the header. It can have several paragraphs.
3. If there are footers, they start after **one blank line** below the body (or the header, if there is no body).

## Types

| Type | Use it for | Version effect |
| --- | --- | --- |
| `feat` | A new feature for users | MINOR |
| `fix` | A bug fix | PATCH |
| `docs` | Documentation only (README, viva cheat sheet, report) | none |
| `style` | Formatting, whitespace, naming; no change in behaviour | none |
| `refactor` | Code change that neither fixes a bug nor adds a feature | none |
| `perf` | Code change that improves performance | none |
| `test` | Adding or correcting tests | none |
| `build` | Build system or dependencies (Swift packages, Xcode settings) | none |
| `ci` | CI configuration (GitHub Actions workflows) | none |
| `chore` | Other maintenance that does not touch source or tests | none |
| `revert` | Reverts an earlier commit | depends |

`feat` and `fix` are defined by the specification. The other types follow the widely used `@commitlint/config-conventional` list. Only the types in this table are accepted here. Write types in lowercase.

## Scopes

A scope is an optional noun in parentheses that names the part of GymLog the commit touches. Use one of these:

| Scope | Area |
| --- | --- |
| `auth` | Firebase login, sign up, logout, validation, session handling |
| `workout` | Creating, editing, viewing and deleting workouts |
| `exercise` | Logging, editing and deleting exercises (sets, reps, weight) inside a workout |
| `library` | Exercise library, `exercises.json`, search and muscle group filter |
| `records` | Personal records and weekly summary calculations |
| `history` | Workout history grouped by date |
| `timer` | Rest timer and progress ring |
| `reminder` | Daily workout reminder and `NotificationManager` |
| `settings` | Settings and profile screen |
| `firestore` | Firestore structure, queries and `firestore.rules` |
| `ui` | Shared layout, components, colours, accessibility and navigation |
| `models` | Data models (`Workout`, `LoggedExercise`, `LibraryExercise`) |
| `deps` | Dependency updates (Firebase SDK) |
| `repo` | Repository setup, hooks, templates, `.gitignore` |
| `readme` | `README.md` and setup instructions |
| `viva` | Viva cheat sheet and course notes |

Scopes are lowercase letters, digits and hyphens. Leave the scope out when a change spans many areas. If you need a new scope, add it to this table in the same commit.

## Description

- Use the imperative mood: "add", "fix", "remove", not "added" or "fixes".
- Start with a lowercase letter and do not end with a period.
- Keep the whole header at **72 characters or fewer**.
- Say what the commit does, not how you got there.

## Body

- Explain **what** changed and **why**, not how.
- Wrap lines at about 72 characters.
- Separate paragraphs with a blank line.

## Breaking changes

A breaking change is anything that forces other code, data or users to change: a renamed Firestore field, a moved collection path, a changed security rule, a raised minimum iOS version. It triggers a MAJOR version bump and can be used with any type.

Mark it in one or both of these ways:

1. Add `!` right before the colon: `feat(firestore)!: move exercises to a new collection path`.
2. Add a footer that starts with `BREAKING CHANGE:` (uppercase) and explains the change and what others must do.

```
feat(firestore)!: store weight in grams instead of kilograms

BREAKING CHANGE: the weight field on logged exercises is now an
integer in grams. Existing documents must be migrated before
running the new build.
```

`BREAKING-CHANGE:` is accepted as a synonym in footers.

## Footers

Footers use the Git trailer format: a token, then `: ` or ` #`, then a value. Tokens use hyphens instead of spaces, except `BREAKING CHANGE`.

```
Refs: #12
Closes: #34
Reviewed-by: Rahim
```

Reference GitHub issues in footers whenever a commit relates to one.

## One change per commit

If a change fits more than one type, split it into separate commits. For example, a new feature and its unrelated bug fix go in two commits.

## Examples

```
feat(auth): add email and password sign up
```

```
fix(timer): invalidate timer when the screen disappears
```

```
feat(exercise): log sets, reps and weight for each exercise

Users can pick an exercise from the library and use steppers for
sets and reps. Weight is entered with a decimal pad.

Refs: #18
```

```
docs(readme): add Firebase setup steps
```

```
test(records): cover personal record calculation with equal weights
```

```
refactor(workout): move Firestore calls into WorkoutViewModel
```

```
feat(firestore)!: store weight in grams instead of kilograms

BREAKING CHANGE: the weight field on logged exercises is now an
integer in grams. Existing documents must be migrated before
running the new build.
```

```
revert: show reminder banner only in background

Refs: 676104e
```

## Messages that are rejected

| Message | Problem |
| --- | --- |
| `Added rest timer` | No type |
| `feature(timer): add rest timer` | `feature` is not an accepted type |
| `feat(Timer): add rest timer` | Scope must be lowercase |
| `feat(timer):add rest timer` | Missing space after the colon |
| `feat(timer): ` | Empty description |
| `fix: update stuff` followed directly by body text | Body must start after a blank line |

## Exceptions

The checks skip these automatically generated messages:

- Merge commits created by Git or GitHub (`Merge branch ...`, `Merge pull request ...`).
- `fixup!` and `squash!` commits made by `git commit --fixup`, which must be squashed before pushing.

## Fixing a bad message

- **Last commit, not pushed yet:** `git commit --amend`
- **Older commits, not pushed yet:** `git rebase -i HEAD~N`, then mark the commits as `reword`.
- **Already pushed to `main`:** do not rewrite shared history. Tell the team, and follow the rules from the next commit on.
