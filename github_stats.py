#!/usr/bin/python

import sys
from github import Github
from datetime import datetime


class GS:
    def __init__(self, user, password):
        self.g = Github(user,password)

    def get_repo_id(self, name):
        for repo in self.g.get_user().get_repos():
            if name == repo.name:
                return repo.id
        return None

    def print_issues(self, repo_id, alert_days=5):
        r = self.g.get_repo(repo_id)
        for issue in r.get_issues():
            if issue.state == "open":
                update_delta=datetime.now()-issue.updated_at
                if update_delta.days > alert_days:
                    text="#%i   %s (%s) (Updated %i days ago)" % (  issue.number,
                                                                    issue.title,
                                                                    issue.html_url,
                                                                    update_delta.days)
                    print text

    def print_pulls(self, repo_id, alert_days=5):
        r = self.g.get_repo(repo_id)
        for pull in r.get_pulls('all'):
            if pull.state == "open":
                update_delta=datetime.now()-pull.updated_at
                if update_delta.days > alert_days:
                    text="#%i   %s (%s) (Updated %i days ago)" % (  pull.number,
                                                                    pull.title,
                                                                    pull.html_url,
                                                                    update_delta.days)
                    print text


def print_stats(user,password):
    ghub=GS(user,password)
    repo_turris=ghub.get_repo_id("turris-os")
    repo_packages=ghub.get_repo_id("turris-os-packages")

    print
    print "Turris OS"
    print "========="
    print "Merge requests:"
    ghub.print_pulls(repo_turris)
    print "Issues:"
    ghub.print_issues(repo_turris)

    print
    print "Turris OS packages"
    print "========="
    print "Merge requests:"
    ghub.print_pulls(repo_packages)
    print "Issues:"
    ghub.print_issues(repo_packages)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        user,password=sys.argv[1:]
        print_stats(user, password)
    else:
        print "Help:"
        print "Mandatory arguments to access github account."
        print "user","password"
