### How to play (for developers)

## Install NodeJS
- project runs on node v24.13.0
- npm i inside the root folder (AstroBlaster/AstroBlasterAPI) to create the node modules

## Install ngrok
- npm i ngrok inside the root folder (AstroBlaster/AstroBlasterAPI)
- visit the website and make an account (free version is enough)
- get your API key

## how to start up
- npm run dev inside the root folder (AstroBlaster/AstroBlasterAPI)
- open a new terminal window and run ngrok http 3000 to expose localhost port 3000
- if this is the first time it will ask for veryfication, it will ask you to paste the API key

# The backend should now be up and running since this connects the application and our MongoDB instance.

## Troubleshooting
- if it doesnt work and no scores show up inside the leaderboards, it might be that differing accounts create different exposed URLs. Check AstroBlaster/AstroBlaster/backend/BackendService.swift and look if the baseURL (line 10) matches the one that you just exposed your localhost 3000 to. The one you created is visible inside the terminal that runs ngrok.