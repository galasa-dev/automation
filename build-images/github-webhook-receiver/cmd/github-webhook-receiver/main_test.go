/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCanUnmarshallMinimalJsonPullRequestOpen(t *testing.T) {
	payloadString := `{
		"action": "opened",
		"pull_request": {
			"url": "https://api.github.com/repos/galasa-dev/automation/pulls/119",
			
			"issue_url": "https://api.github.com/repos/galasa-dev/automation/issues/119",
			"state": "open",
			"title": "empty commit to kick a build off",
			"statuses_url": "https://api.github.com/repos/galasa-dev/automation/statuses/64f1ffbb8040574f44998423f2a436b7e16b8dfb"
		}
	}`
	bytes := []byte(payloadString)

	pPayload, err := unmarshallPayload(bytes)

	if assert.Nil(t, err) {
		assert.Equal(t, "opened", pPayload.Action, "Parsing payload failed to pick up the action.")
	}
}

func TestCanUnmarshallPullRequestOpen(t *testing.T) {
	payloadString := `{
		"action": "opened",
		"number": 119,
		"pull_request": {
			"url": "https://api.github.com/repos/galasa-dev/automation/pulls/119",
			"id": 1175315220,
			"node_id": "PR_kwDOH8-0185GDeMU",
			"html_url": "https://github.com/galasa-dev/automation/pull/119",
			"diff_url": "https://github.com/galasa-dev/automation/pull/119.diff",
			"patch_url": "https://github.com/galasa-dev/automation/pull/119.patch",
			"issue_url": "https://api.github.com/repos/galasa-dev/automation/issues/119",
			"number": 119,
			"state": "open",
			"locked": false,
			"title": "empty commit to kick a build off",
			"user": {
				"login": "techcobweb",
				"id": 77053,
				"node_id": "MDQ6VXNlcjc3MDUz",
				"avatar_url": "https://avatars.githubusercontent.com/u/77053?v=4",
				"gravatar_id": "",
				"url": "https://api.github.com/users/techcobweb",
				"html_url": "https://github.com/techcobweb",
				"followers_url": "https://api.github.com/users/techcobweb/followers",
				"following_url": "https://api.github.com/users/techcobweb/following{/other_user}",
				"gists_url": "https://api.github.com/users/techcobweb/gists{/gist_id}",
				"starred_url": "https://api.github.com/users/techcobweb/starred{/owner}{/repo}",
				"subscriptions_url": "https://api.github.com/users/techcobweb/subscriptions",
				"organizations_url": "https://api.github.com/users/techcobweb/orgs",
				"repos_url": "https://api.github.com/users/techcobweb/repos",
				"events_url": "https://api.github.com/users/techcobweb/events{/privacy}",
				"received_events_url": "https://api.github.com/users/techcobweb/received_events",
				"type": "User",
				"site_admin": false
			},
			"body": "Signed-off-by: Mike Cobbett <77053+techcobweb@users.noreply.github.com>\n",
			"created_at": "2022-12-22T15:49:16Z",
			"updated_at": "2022-12-22T15:49:16Z",
			"closed_at": null,
			"merged_at": null,
			"merge_commit_sha": null,
			"assignee": null,
			"assignees": [],
			"requested_reviewers": [],
			"requested_teams": [],
			"labels": [],
			"milestone": null,
			"draft": false,
			"commits_url": "https://api.github.com/repos/galasa-dev/automation/pulls/119/commits",
			"review_comments_url": "https://api.github.com/repos/galasa-dev/automation/pulls/119/comments",
			"review_comment_url": "https://api.github.com/repos/galasa-dev/automation/pulls/comments{/number}",
			"comments_url": "https://api.github.com/repos/galasa-dev/automation/issues/119/comments",
			"statuses_url": "https://api.github.com/repos/galasa-dev/automation/statuses/64f1ffbb8040574f44998423f2a436b7e16b8dfb",
			"head": {
				"label": "galasa-dev:webhook-receiver",
				"ref": "webhook-receiver",
				"sha": "64f1ffbb8040574f44998423f2a436b7e16b8dfb",
				"user": {
					"login": "galasa-dev",
					"id": 53180681,
					"node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMTgwNjgx",
					"avatar_url": "https://avatars.githubusercontent.com/u/53180681?v=4",
					"gravatar_id": "",
					"url": "https://api.github.com/users/galasa-dev",
					"html_url": "https://github.com/galasa-dev",
					"followers_url": "https://api.github.com/users/galasa-dev/followers",
					"following_url": "https://api.github.com/users/galasa-dev/following{/other_user}",
					"gists_url": "https://api.github.com/users/galasa-dev/gists{/gist_id}",
					"starred_url": "https://api.github.com/users/galasa-dev/starred{/owner}{/repo}",
					"subscriptions_url": "https://api.github.com/users/galasa-dev/subscriptions",
					"organizations_url": "https://api.github.com/users/galasa-dev/orgs",
					"repos_url": "https://api.github.com/users/galasa-dev/repos",
					"events_url": "https://api.github.com/users/galasa-dev/events{/privacy}",
					"received_events_url": "https://api.github.com/users/galasa-dev/received_events",
					"type": "Organization",
					"site_admin": false
				},
				"repo": {
					"id": 533705943,
					"node_id": "R_kgDOH8-01w",
					"name": "automation",
					"full_name": "galasa-dev/automation",
					"private": false,
					"owner": {
						"login": "galasa-dev",
						"id": 53180681,
						"node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMTgwNjgx",
						"avatar_url": "https://avatars.githubusercontent.com/u/53180681?v=4",
						"gravatar_id": "",
						"url": "https://api.github.com/users/galasa-dev",
						"html_url": "https://github.com/galasa-dev",
						"followers_url": "https://api.github.com/users/galasa-dev/followers",
						"following_url": "https://api.github.com/users/galasa-dev/following{/other_user}",
						"gists_url": "https://api.github.com/users/galasa-dev/gists{/gist_id}",
						"starred_url": "https://api.github.com/users/galasa-dev/starred{/owner}{/repo}",
						"subscriptions_url": "https://api.github.com/users/galasa-dev/subscriptions",
						"organizations_url": "https://api.github.com/users/galasa-dev/orgs",
						"repos_url": "https://api.github.com/users/galasa-dev/repos",
						"events_url": "https://api.github.com/users/galasa-dev/events{/privacy}",
						"received_events_url": "https://api.github.com/users/galasa-dev/received_events",
						"type": "Organization",
						"site_admin": false
					},
					"html_url": "https://github.com/galasa-dev/automation",
					"description": null,
					"fork": false,
					"url": "https://api.github.com/repos/galasa-dev/automation",
					"forks_url": "https://api.github.com/repos/galasa-dev/automation/forks",
					"keys_url": "https://api.github.com/repos/galasa-dev/automation/keys{/key_id}",
					"collaborators_url": "https://api.github.com/repos/galasa-dev/automation/collaborators{/collaborator}",
					"teams_url": "https://api.github.com/repos/galasa-dev/automation/teams",
					"hooks_url": "https://api.github.com/repos/galasa-dev/automation/hooks",
					"issue_events_url": "https://api.github.com/repos/galasa-dev/automation/issues/events{/number}",
					"events_url": "https://api.github.com/repos/galasa-dev/automation/events",
					"assignees_url": "https://api.github.com/repos/galasa-dev/automation/assignees{/user}",
					"branches_url": "https://api.github.com/repos/galasa-dev/automation/branches{/branch}",
					"tags_url": "https://api.github.com/repos/galasa-dev/automation/tags",
					"blobs_url": "https://api.github.com/repos/galasa-dev/automation/git/blobs{/sha}",
					"git_tags_url": "https://api.github.com/repos/galasa-dev/automation/git/tags{/sha}",
					"git_refs_url": "https://api.github.com/repos/galasa-dev/automation/git/refs{/sha}",
					"trees_url": "https://api.github.com/repos/galasa-dev/automation/git/trees{/sha}",
					"statuses_url": "https://api.github.com/repos/galasa-dev/automation/statuses/{sha}",
					"languages_url": "https://api.github.com/repos/galasa-dev/automation/languages",
					"stargazers_url": "https://api.github.com/repos/galasa-dev/automation/stargazers",
					"contributors_url": "https://api.github.com/repos/galasa-dev/automation/contributors",
					"subscribers_url": "https://api.github.com/repos/galasa-dev/automation/subscribers",
					"subscription_url": "https://api.github.com/repos/galasa-dev/automation/subscription",
					"commits_url": "https://api.github.com/repos/galasa-dev/automation/commits{/sha}",
					"git_commits_url": "https://api.github.com/repos/galasa-dev/automation/git/commits{/sha}",
					"comments_url": "https://api.github.com/repos/galasa-dev/automation/comments{/number}",
					"issue_comment_url": "https://api.github.com/repos/galasa-dev/automation/issues/comments{/number}",
					"contents_url": "https://api.github.com/repos/galasa-dev/automation/contents/{+path}",
					"compare_url": "https://api.github.com/repos/galasa-dev/automation/compare/{base}...{head}",
					"merges_url": "https://api.github.com/repos/galasa-dev/automation/merges",
					"archive_url": "https://api.github.com/repos/galasa-dev/automation/{archive_format}{/ref}",
					"downloads_url": "https://api.github.com/repos/galasa-dev/automation/downloads",
					"issues_url": "https://api.github.com/repos/galasa-dev/automation/issues{/number}",
					"pulls_url": "https://api.github.com/repos/galasa-dev/automation/pulls{/number}",
					"milestones_url": "https://api.github.com/repos/galasa-dev/automation/milestones{/number}",
					"notifications_url": "https://api.github.com/repos/galasa-dev/automation/notifications{?since,all,participating}",
					"labels_url": "https://api.github.com/repos/galasa-dev/automation/labels{/name}",
					"releases_url": "https://api.github.com/repos/galasa-dev/automation/releases{/id}",
					"deployments_url": "https://api.github.com/repos/galasa-dev/automation/deployments",
					"created_at": "2022-09-07T09:57:18Z",
					"updated_at": "2022-12-09T16:30:25Z",
					"pushed_at": "2022-12-22T15:49:16Z",
					"git_url": "git://github.com/galasa-dev/automation.git",
					"ssh_url": "git@github.com:galasa-dev/automation.git",
					"clone_url": "https://github.com/galasa-dev/automation.git",
					"svn_url": "https://github.com/galasa-dev/automation",
					"homepage": null,
					"size": 2554,
					"stargazers_count": 1,
					"watchers_count": 1,
					"language": "Go",
					"has_issues": true,
					"has_projects": true,
					"has_downloads": true,
					"has_wiki": true,
					"has_pages": false,
					"has_discussions": false,
					"forks_count": 1,
					"mirror_url": null,
					"archived": false,
					"disabled": false,
					"open_issues_count": 4,
					"license": {
						"key": "apache-2.0",
						"name": "Apache License 2.0",
						"spdx_id": "Apache-2.0",
						"url": "https://api.github.com/licenses/apache-2.0",
						"node_id": "MDc6TGljZW5zZTI="
					},
					"allow_forking": true,
					"is_template": false,
					"web_commit_signoff_required": false,
					"topics": [],
					"visibility": "public",
					"forks": 1,
					"open_issues": 4,
					"watchers": 1,
					"default_branch": "main",
					"allow_squash_merge": true,
					"allow_merge_commit": true,
					"allow_rebase_merge": true,
					"allow_auto_merge": false,
					"delete_branch_on_merge": false,
					"allow_update_branch": false,
					"use_squash_pr_title_as_default": false,
					"squash_merge_commit_message": "COMMIT_MESSAGES",
					"squash_merge_commit_title": "COMMIT_OR_PR_TITLE",
					"merge_commit_message": "PR_TITLE",
					"merge_commit_title": "MERGE_MESSAGE"
				}
			},
			"base": {
				"label": "galasa-dev:main",
				"ref": "main",
				"sha": "7519cea732fafb7965700bca833d613ed24dfdea",
				"user": {
					"login": "galasa-dev",
					"id": 53180681,
					"node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMTgwNjgx",
					"avatar_url": "https://avatars.githubusercontent.com/u/53180681?v=4",
					"gravatar_id": "",
					"url": "https://api.github.com/users/galasa-dev",
					"html_url": "https://github.com/galasa-dev",
					"followers_url": "https://api.github.com/users/galasa-dev/followers",
					"following_url": "https://api.github.com/users/galasa-dev/following{/other_user}",
					"gists_url": "https://api.github.com/users/galasa-dev/gists{/gist_id}",
					"starred_url": "https://api.github.com/users/galasa-dev/starred{/owner}{/repo}",
					"subscriptions_url": "https://api.github.com/users/galasa-dev/subscriptions",
					"organizations_url": "https://api.github.com/users/galasa-dev/orgs",
					"repos_url": "https://api.github.com/users/galasa-dev/repos",
					"events_url": "https://api.github.com/users/galasa-dev/events{/privacy}",
					"received_events_url": "https://api.github.com/users/galasa-dev/received_events",
					"type": "Organization",
					"site_admin": false
				},
				"repo": {
					"id": 533705943,
					"node_id": "R_kgDOH8-01w",
					"name": "automation",
					"full_name": "galasa-dev/automation",
					"private": false,
					"owner": {
						"login": "galasa-dev",
						"id": 53180681,
						"node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMTgwNjgx",
						"avatar_url": "https://avatars.githubusercontent.com/u/53180681?v=4",
						"gravatar_id": "",
						"url": "https://api.github.com/users/galasa-dev",
						"html_url": "https://github.com/galasa-dev",
						"followers_url": "https://api.github.com/users/galasa-dev/followers",
						"following_url": "https://api.github.com/users/galasa-dev/following{/other_user}",
						"gists_url": "https://api.github.com/users/galasa-dev/gists{/gist_id}",
						"starred_url": "https://api.github.com/users/galasa-dev/starred{/owner}{/repo}",
						"subscriptions_url": "https://api.github.com/users/galasa-dev/subscriptions",
						"organizations_url": "https://api.github.com/users/galasa-dev/orgs",
						"repos_url": "https://api.github.com/users/galasa-dev/repos",
						"events_url": "https://api.github.com/users/galasa-dev/events{/privacy}",
						"received_events_url": "https://api.github.com/users/galasa-dev/received_events",
						"type": "Organization",
						"site_admin": false
					},
					"html_url": "https://github.com/galasa-dev/automation",
					"description": null,
					"fork": false,
					"url": "https://api.github.com/repos/galasa-dev/automation",
					"forks_url": "https://api.github.com/repos/galasa-dev/automation/forks",
					"keys_url": "https://api.github.com/repos/galasa-dev/automation/keys{/key_id}",
					"collaborators_url": "https://api.github.com/repos/galasa-dev/automation/collaborators{/collaborator}",
					"teams_url": "https://api.github.com/repos/galasa-dev/automation/teams",
					"hooks_url": "https://api.github.com/repos/galasa-dev/automation/hooks",
					"issue_events_url": "https://api.github.com/repos/galasa-dev/automation/issues/events{/number}",
					"events_url": "https://api.github.com/repos/galasa-dev/automation/events",
					"assignees_url": "https://api.github.com/repos/galasa-dev/automation/assignees{/user}",
					"branches_url": "https://api.github.com/repos/galasa-dev/automation/branches{/branch}",
					"tags_url": "https://api.github.com/repos/galasa-dev/automation/tags",
					"blobs_url": "https://api.github.com/repos/galasa-dev/automation/git/blobs{/sha}",
					"git_tags_url": "https://api.github.com/repos/galasa-dev/automation/git/tags{/sha}",
					"git_refs_url": "https://api.github.com/repos/galasa-dev/automation/git/refs{/sha}",
					"trees_url": "https://api.github.com/repos/galasa-dev/automation/git/trees{/sha}",
					"statuses_url": "https://api.github.com/repos/galasa-dev/automation/statuses/{sha}",
					"languages_url": "https://api.github.com/repos/galasa-dev/automation/languages",
					"stargazers_url": "https://api.github.com/repos/galasa-dev/automation/stargazers",
					"contributors_url": "https://api.github.com/repos/galasa-dev/automation/contributors",
					"subscribers_url": "https://api.github.com/repos/galasa-dev/automation/subscribers",
					"subscription_url": "https://api.github.com/repos/galasa-dev/automation/subscription",
					"commits_url": "https://api.github.com/repos/galasa-dev/automation/commits{/sha}",
					"git_commits_url": "https://api.github.com/repos/galasa-dev/automation/git/commits{/sha}",
					"comments_url": "https://api.github.com/repos/galasa-dev/automation/comments{/number}",
					"issue_comment_url": "https://api.github.com/repos/galasa-dev/automation/issues/comments{/number}",
					"contents_url": "https://api.github.com/repos/galasa-dev/automation/contents/{+path}",
					"compare_url": "https://api.github.com/repos/galasa-dev/automation/compare/{base}...{head}",
					"merges_url": "https://api.github.com/repos/galasa-dev/automation/merges",
					"archive_url": "https://api.github.com/repos/galasa-dev/automation/{archive_format}{/ref}",
					"downloads_url": "https://api.github.com/repos/galasa-dev/automation/downloads",
					"issues_url": "https://api.github.com/repos/galasa-dev/automation/issues{/number}",
					"pulls_url": "https://api.github.com/repos/galasa-dev/automation/pulls{/number}",
					"milestones_url": "https://api.github.com/repos/galasa-dev/automation/milestones{/number}",
					"notifications_url": "https://api.github.com/repos/galasa-dev/automation/notifications{?since,all,participating}",
					"labels_url": "https://api.github.com/repos/galasa-dev/automation/labels{/name}",
					"releases_url": "https://api.github.com/repos/galasa-dev/automation/releases{/id}",
					"deployments_url": "https://api.github.com/repos/galasa-dev/automation/deployments",
					"created_at": "2022-09-07T09:57:18Z",
					"updated_at": "2022-12-09T16:30:25Z",
					"pushed_at": "2022-12-22T15:49:16Z",
					"git_url": "git://github.com/galasa-dev/automation.git",
					"ssh_url": "git@github.com:galasa-dev/automation.git",
					"clone_url": "https://github.com/galasa-dev/automation.git",
					"svn_url": "https://github.com/galasa-dev/automation",
					"homepage": null,
					"size": 2554,
					"stargazers_count": 1,
					"watchers_count": 1,
					"language": "Go",
					"has_issues": true,
					"has_projects": true,
					"has_downloads": true,
					"has_wiki": true,
					"has_pages": false,
					"has_discussions": false,
					"forks_count": 1,
					"mirror_url": null,
					"archived": false,
					"disabled": false,
					"open_issues_count": 4,
					"license": {
						"key": "apache-2.0",
						"name": "Apache License 2.0",
						"spdx_id": "Apache-2.0",
						"url": "https://api.github.com/licenses/apache-2.0",
						"node_id": "MDc6TGljZW5zZTI="
					},
					"allow_forking": true,
					"is_template": false,
					"web_commit_signoff_required": false,
					"topics": [],
					"visibility": "public",
					"forks": 1,
					"open_issues": 4,
					"watchers": 1,
					"default_branch": "main",
					"allow_squash_merge": true,
					"allow_merge_commit": true,
					"allow_rebase_merge": true,
					"allow_auto_merge": false,
					"delete_branch_on_merge": false,
					"allow_update_branch": false,
					"use_squash_pr_title_as_default": false,
					"squash_merge_commit_message": "COMMIT_MESSAGES",
					"squash_merge_commit_title": "COMMIT_OR_PR_TITLE",
					"merge_commit_message": "PR_TITLE",
					"merge_commit_title": "MERGE_MESSAGE"
				}
			},
			"_links": {
				"self": {
					"href": "https://api.github.com/repos/galasa-dev/automation/pulls/119"
				},
				"html": {
					"href": "https://github.com/galasa-dev/automation/pull/119"
				},
				"issue": {
					"href": "https://api.github.com/repos/galasa-dev/automation/issues/119"
				},
				"comments": {
					"href": "https://api.github.com/repos/galasa-dev/automation/issues/119/comments"
				},
				"review_comments": {
					"href": "https://api.github.com/repos/galasa-dev/automation/pulls/119/comments"
				},
				"review_comment": {
					"href": "https://api.github.com/repos/galasa-dev/automation/pulls/comments{/number}"
				},
				"commits": {
					"href": "https://api.github.com/repos/galasa-dev/automation/pulls/119/commits"
				},
				"statuses": {
					"href": "https://api.github.com/repos/galasa-dev/automation/statuses/64f1ffbb8040574f44998423f2a436b7e16b8dfb"
				}
			},
			"author_association": "CONTRIBUTOR",
			"auto_merge": null,
			"active_lock_reason": null,
			"merged": false,
			"mergeable": null,
			"rebaseable": null,
			"mergeable_state": "unknown",
			"merged_by": null,
			"comments": 0,
			"review_comments": 0,
			"maintainer_can_modify": false,
			"commits": 1,
			"additions": 0,
			"deletions": 0,
			"changed_files": 0
		},
		"repository": {
			"id": 533705943,
			"node_id": "R_kgDOH8-01w",
			"name": "automation",
			"full_name": "galasa-dev/automation",
			"private": false,
			"owner": {
				"login": "galasa-dev",
				"id": 53180681,
				"node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMTgwNjgx",
				"avatar_url": "https://avatars.githubusercontent.com/u/53180681?v=4",
				"gravatar_id": "",
				"url": "https://api.github.com/users/galasa-dev",
				"html_url": "https://github.com/galasa-dev",
				"followers_url": "https://api.github.com/users/galasa-dev/followers",
				"following_url": "https://api.github.com/users/galasa-dev/following{/other_user}",
				"gists_url": "https://api.github.com/users/galasa-dev/gists{/gist_id}",
				"starred_url": "https://api.github.com/users/galasa-dev/starred{/owner}{/repo}",
				"subscriptions_url": "https://api.github.com/users/galasa-dev/subscriptions",
				"organizations_url": "https://api.github.com/users/galasa-dev/orgs",
				"repos_url": "https://api.github.com/users/galasa-dev/repos",
				"events_url": "https://api.github.com/users/galasa-dev/events{/privacy}",
				"received_events_url": "https://api.github.com/users/galasa-dev/received_events",
				"type": "Organization",
				"site_admin": false
			},
			"html_url": "https://github.com/galasa-dev/automation",
			"description": null,
			"fork": false,
			"url": "https://api.github.com/repos/galasa-dev/automation",
			"forks_url": "https://api.github.com/repos/galasa-dev/automation/forks",
			"keys_url": "https://api.github.com/repos/galasa-dev/automation/keys{/key_id}",
			"collaborators_url": "https://api.github.com/repos/galasa-dev/automation/collaborators{/collaborator}",
			"teams_url": "https://api.github.com/repos/galasa-dev/automation/teams",
			"hooks_url": "https://api.github.com/repos/galasa-dev/automation/hooks",
			"issue_events_url": "https://api.github.com/repos/galasa-dev/automation/issues/events{/number}",
			"events_url": "https://api.github.com/repos/galasa-dev/automation/events",
			"assignees_url": "https://api.github.com/repos/galasa-dev/automation/assignees{/user}",
			"branches_url": "https://api.github.com/repos/galasa-dev/automation/branches{/branch}",
			"tags_url": "https://api.github.com/repos/galasa-dev/automation/tags",
			"blobs_url": "https://api.github.com/repos/galasa-dev/automation/git/blobs{/sha}",
			"git_tags_url": "https://api.github.com/repos/galasa-dev/automation/git/tags{/sha}",
			"git_refs_url": "https://api.github.com/repos/galasa-dev/automation/git/refs{/sha}",
			"trees_url": "https://api.github.com/repos/galasa-dev/automation/git/trees{/sha}",
			"statuses_url": "https://api.github.com/repos/galasa-dev/automation/statuses/{sha}",
			"languages_url": "https://api.github.com/repos/galasa-dev/automation/languages",
			"stargazers_url": "https://api.github.com/repos/galasa-dev/automation/stargazers",
			"contributors_url": "https://api.github.com/repos/galasa-dev/automation/contributors",
			"subscribers_url": "https://api.github.com/repos/galasa-dev/automation/subscribers",
			"subscription_url": "https://api.github.com/repos/galasa-dev/automation/subscription",
			"commits_url": "https://api.github.com/repos/galasa-dev/automation/commits{/sha}",
			"git_commits_url": "https://api.github.com/repos/galasa-dev/automation/git/commits{/sha}",
			"comments_url": "https://api.github.com/repos/galasa-dev/automation/comments{/number}",
			"issue_comment_url": "https://api.github.com/repos/galasa-dev/automation/issues/comments{/number}",
			"contents_url": "https://api.github.com/repos/galasa-dev/automation/contents/{+path}",
			"compare_url": "https://api.github.com/repos/galasa-dev/automation/compare/{base}...{head}",
			"merges_url": "https://api.github.com/repos/galasa-dev/automation/merges",
			"archive_url": "https://api.github.com/repos/galasa-dev/automation/{archive_format}{/ref}",
			"downloads_url": "https://api.github.com/repos/galasa-dev/automation/downloads",
			"issues_url": "https://api.github.com/repos/galasa-dev/automation/issues{/number}",
			"pulls_url": "https://api.github.com/repos/galasa-dev/automation/pulls{/number}",
			"milestones_url": "https://api.github.com/repos/galasa-dev/automation/milestones{/number}",
			"notifications_url": "https://api.github.com/repos/galasa-dev/automation/notifications{?since,all,participating}",
			"labels_url": "https://api.github.com/repos/galasa-dev/automation/labels{/name}",
			"releases_url": "https://api.github.com/repos/galasa-dev/automation/releases{/id}",
			"deployments_url": "https://api.github.com/repos/galasa-dev/automation/deployments",
			"created_at": "2022-09-07T09:57:18Z",
			"updated_at": "2022-12-09T16:30:25Z",
			"pushed_at": "2022-12-22T15:49:16Z",
			"git_url": "git://github.com/galasa-dev/automation.git",
			"ssh_url": "git@github.com:galasa-dev/automation.git",
			"clone_url": "https://github.com/galasa-dev/automation.git",
			"svn_url": "https://github.com/galasa-dev/automation",
			"homepage": null,
			"size": 2554,
			"stargazers_count": 1,
			"watchers_count": 1,
			"language": "Go",
			"has_issues": true,
			"has_projects": true,
			"has_downloads": true,
			"has_wiki": true,
			"has_pages": false,
			"has_discussions": false,
			"forks_count": 1,
			"mirror_url": null,
			"archived": false,
			"disabled": false,
			"open_issues_count": 4,
			"license": {
				"key": "apache-2.0",
				"name": "Apache License 2.0",
				"spdx_id": "Apache-2.0",
				"url": "https://api.github.com/licenses/apache-2.0",
				"node_id": "MDc6TGljZW5zZTI="
			},
			"allow_forking": true,
			"is_template": false,
			"web_commit_signoff_required": false,
			"topics": [],
			"visibility": "public",
			"forks": 1,
			"open_issues": 4,
			"watchers": 1,
			"default_branch": "main"
		},
		"organization": {
			"login": "galasa-dev",
			"id": 53180681,
			"node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMTgwNjgx",
			"url": "https://api.github.com/orgs/galasa-dev",
			"repos_url": "https://api.github.com/orgs/galasa-dev/repos",
			"events_url": "https://api.github.com/orgs/galasa-dev/events",
			"hooks_url": "https://api.github.com/orgs/galasa-dev/hooks",
			"issues_url": "https://api.github.com/orgs/galasa-dev/issues",
			"members_url": "https://api.github.com/orgs/galasa-dev/members{/member}",
			"public_members_url": "https://api.github.com/orgs/galasa-dev/public_members{/member}",
			"avatar_url": "https://avatars.githubusercontent.com/u/53180681?v=4",
			"description": "Galasa is an open source deep integration test framework, To learn more, take a look at https://galasa.dev "
		},
		"sender": {
			"login": "techcobweb",
			"id": 77053,
			"node_id": "MDQ6VXNlcjc3MDUz",
			"avatar_url": "https://avatars.githubusercontent.com/u/77053?v=4",
			"gravatar_id": "",
			"url": "https://api.github.com/users/techcobweb",
			"html_url": "https://github.com/techcobweb",
			"followers_url": "https://api.github.com/users/techcobweb/followers",
			"following_url": "https://api.github.com/users/techcobweb/following{/other_user}",
			"gists_url": "https://api.github.com/users/techcobweb/gists{/gist_id}",
			"starred_url": "https://api.github.com/users/techcobweb/starred{/owner}{/repo}",
			"subscriptions_url": "https://api.github.com/users/techcobweb/subscriptions",
			"organizations_url": "https://api.github.com/users/techcobweb/orgs",
			"repos_url": "https://api.github.com/users/techcobweb/repos",
			"events_url": "https://api.github.com/users/techcobweb/events{/privacy}",
			"received_events_url": "https://api.github.com/users/techcobweb/received_events",
			"type": "User",
			"site_admin": false
		}
	}`
	bytes := []byte(payloadString)

	pPayload, err := unmarshallPayload(bytes)

	if assert.Nil(t, err) {
		assert.Equal(t, "opened", pPayload.Action, "Parsing payload failed to pick up the action.")
	}
}

func TestIsExcludedWhenThereAreNoExclusionsShouldNotExclude(t *testing.T) {
	excludedRepositories := make([]string, 0)
	repoName := "notToBeExcludedRepo"

	result := isExcluded(repoName, excludedRepositories)
	assert.False(t, result, "Should not be excluded, but it was.")
}

func TestIsExcludedWhenThereAreTwoDifferingExclusionsShouldNotExclude(t *testing.T) {
	excludedRepositories := []string {"notMatching1","notMatching2"}
	repoName := "notToBeExcludedRepo"

	result := isExcluded(repoName, excludedRepositories)
	assert.False(t, result, "Should not be excluded, but it was.")
}

func TestIsExcludedShouldExcludeIfThereIsAMatch(t *testing.T) {
	excludedRepositories := []string {"notMatching1","matching2"}
	repoName := "matching2"

	result := isExcluded(repoName, excludedRepositories)
	assert.True(t, result, "Should be excluded, but it was not.")
}