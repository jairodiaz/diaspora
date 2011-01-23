@javascript @wip
Feature: deleting a post

Scenario: delete post
 	Given I am signed in
        And I am on the home page
      	And I click share across aspects
        And I fill in "status_message_message" with "I am eating a yogurt"
        And I press "Share"
	And I wait for the ajax to finish
	When I delete the last status
	And I am on the home page
