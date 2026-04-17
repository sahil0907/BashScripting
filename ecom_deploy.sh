#Author: Sahil Sharma
#About: Using this script we are deploying a python-flask appliction(Ecom.) on a different machine, we have files on our host system and we will transfer those files to our server and install every dependency and run our application there and test if its running or not. 

#make a specific user for this and only this user will be used to run this appliction, so change the ownership of this ecom folder to this user

#/bin/bash



# Update the package list
sudo apt update

# Install Python3, Virtual Environment tool, and Pip
sudo apt install python3 python3-pip python3-venv build-essential -y

mkdir -p ~/ecomm-app
cd ~/ecomm-app

python3 -m venv my-venv
source my-venv/bin/activate
pip install flask flask-sqlalchemy

#here we get code files from remote server
rsync -avz sahil@192.168.0.104:/home/sahil/for_share/  ~/ecomm-app/
cd ~/ecomm-app
mkdir app
mv *.py app/
cd app
mkdir  static templates
cd ..
mv *.js app/static/
mv *.html app/templates/

#try to run the application
nohup python3 app/app.py > app.log 2>&1 &
FLASK_PID=$!
echo "Flask started with PID: $FLASK_PID"

# 4. Wait for the server to initialize
echo "Waiting 5 seconds for startup..."
sleep 5

# 5. Run your test
echo "Running Health Check..."
curl -v http://127.0.0.1:5000/health

# 6. Kill the application
echo "Testing complete. Closing application..."
#kill $FLASK_PID

echo "Application stopped. DONE"

