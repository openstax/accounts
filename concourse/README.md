# Accounts Concourse Automation
Scott: As part of porting accounts to a new deployment type, I am also getting a pipeline set up to automatically build create an image with all the deployment code that will be used to build am accounts AMI when a merge to master happens. 

I think best practice may be to make all these into 1 single pipeline but I will keep them separate while I iterate. 

No, I do not know what I am doing; feedback is always welcome, so please don't be shy to point out any concerns you see.

## create-accounts-create-deployment-image.yml
When a merge to `accounts-deployments` happens (currently living in the devops repo), create a new docker image that has all the prereqs and updated deployment code

## build-accounts-build-ami.yml
Using the above docker image, build an accounts ami when a merge to `new-deployment` branch happens. 

## accounts-create-sandbox.yml

## accounts-test-sandbox.yml

## accounts-copy-ami-to-prod.yml

## accounts-create-or-update-staging.yml 

## accounts-test-staging.yml

## accounts-update-prod.yml

## accounts-test-prod.yml
