#!/bin/bash
sudo apt  update -qq >/dev/null 2>&1
#looping through the dependencies
PACKAGES=(python3 python3-pip python3-venv build-essential rsync)
for pkg in "${PACKAGES[@]}"
do
	if ! dpkg -s "$pkg" >/dev/null 2>&1
	then	
	  sudo apt install -y "$pkg"
	fi
done
#creating the directory structure
mkdir -p ~/ecomm-app/app/static ~/ecomm-app/app/templates ~/ecomm-app/app/static/css/
#get source code note: we dont have a env file in our sharing folder , if we had that file then we have to use --exlude option for rysnc to ignore that file
rysnc -avz sahil@192.168.0.104:/home/sahil/for_share/ ~/ecomm-app
#organize files needed in different folder
find ~/ecomm-app -maxdepth 1 -name "*.py" -exec mv {} ~/ecomm-app/app/ \;
find ~/ecomm-app -maxdepth 1 -name "*.js" -exec mv {} ~/ecomm-app/app/static/ \;
find ~/ecomm-app -maxdepth 1 -name "*.html" -exec mv {} ~/ecomm-app/app/template/ \;
find ~/ecomm-app -maxdepth 1 -name "*.css" -exec mv {} ~/ecomm-app/app/static/css/ \;
cd ~/ecomm-app
#check if the virtual env exists or not
if [ ! -d my-venv ]
then
	python3 -m venv my-venv
fi
#to avoid source errors using absolute path for commands
./my-venv/bin/pip install --upgrade pip
./my-venv/bin/pip install flask flask-sqlalchemy

EXISTING_PID=$(lsof -t -i:5000)
if [ ! -z "$EXISTING_PID" ]
then
	echo "Cleaning up existing process on port 5000.."
	kill -9 $EXISTING_PID
fi

#running appliction and health check
nohup ./my-venv/bin/python3 app/app.py >app.log 2>&1 &
FLASK_PID=$!
echo "Waiting for startup..."
sleep 5

if curl -s --head http://127.0.0.1:5000/health | grep "200 OK" > /dev/null
then
	echo "Health check done"
else
	echo "Failed health check"
	exit 1
fi

echo "Deployed Application with $FLASK_PID PID"

