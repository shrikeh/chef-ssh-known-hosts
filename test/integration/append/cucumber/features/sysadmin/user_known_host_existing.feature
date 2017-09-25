Feature: User has an existing known host file which should have new entries appended to it

Scenario: deploy user has existing entries in their ssh known_hosts file

Given the user account is "deploy"
And their known hosts file is "/tmp/known_hosts"
And there are existing entries
When Chef runs and the node has new known host entries
Then new entries are appended and the existing entries are preserved
