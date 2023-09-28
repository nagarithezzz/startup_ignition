from flask  import Flask,  request, json, jsonify,redirect, render_template, url_for
from passlib.hash import pbkdf2_sha256
import uuid
import urllib.parse
import bcrypt

import requests
import json
import psycopg2
from datetime import datetime
import smtplib

import hashlib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart



app = Flask(__name__)
sha256 = hashlib.sha256()
conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
cur = conn.cursor()
cur.execute(
	'''CREATE TABLE IF NOT EXISTS users(id serial \
	PRIMARY KEY,created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, email varchar(100), name varchar(100),phone varchar(15),whatsapp_no varchar(15),linkedin varchar(100),designation varchar(100),company varchar(100),website varchar(100),aboutCompany varchar(10000),lookingfor varchar(5000), sector varchar(100),websiteReview varchar(10000),additionalInfo varchar(3000),category varchar(100),typeOfStartup varchar(1000),city varchar(100), password varchar(100000), role varchar(50), is_verified BOOLEAN NOT NULL,verification_token varchar(10000),r_token varchar(10000),admin_approved BOOLEAN NOT NULL,fcmtoken varchar(50000));''')
cur.execute(
	'''CREATE TABLE IF NOT EXISTS story(id serial \
	PRIMARY KEY,created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, successstory varchar(10000),amount numeric(1000), partnerNames varchar(100000),phone varchar(15));''')

cur.execute(
	'''CREATE TABLE IF NOT EXISTS friend_request_notifications(id serial \
	PRIMARY KEY,user_email varchar(10000), notification_body text[]);''')
cur.execute(
	'''CREATE TABLE IF NOT EXISTS friends(id serial \
	PRIMARY KEY,user_email varchar(10000), requested_friends text[],pending_friends text[], friends text[]);''')
# cur.execute(
# 	'''CREATE TABLE IF NOT EXISTS jobs(id serial \
# 	PRIMARY KEY, title varchar(10000),c_name varchar(500),email varchar(100), imgurl varchar(100000),content varchar(1000), tags varchar(2000), comments varchar(50000), ccu varchar(100000));''')
# cur.execute(
# 	'''CREATE TABLE IF NOT EXISTS startup(id serial \
# 	PRIMARY KEY, c_name varchar(500),c_desc varchar(2000) ,c_stats varchar(1000), carouselList varchar(100000),c_imgurl varchar(100000), c_value numeric(100));''')
conn.commit()

cur.close()
conn.close()
@app.route("/create", methods=['POST'])
def checkexistance():
    data = request.get_json()
    print(data)
    name = data.get('name')
    password = data.get('password')  
    email = data.get('email')
    phone = data.get('phone')
    role = data.get('accountType')
    whatsapp = data.get('whatsappNumber')
    linkedin = data.get('linkedinProfile')
    designation = data.get('designation')
    company = data.get('company')
    website = data.get('website')
    abtCompany = data.get('aboutCompany')
    lookingfor = data.get('lookingFor')
    sector = data.get('sector')
    websiteReview = data.get('websiteReview')
    addInfo = data.get('additionalInfo')
    category = data.get('category')
    typeofStartup = data.get('typeOfStartup')
    city = data.get('city')
    fcmtoken = data.get('fcmtoken')
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    token = pbkdf2_sha256.hash(email)
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    phone_query = "SELECT COUNT(*) FROM users WHERE phone = %s"
    
    with conn.cursor() as cur:
        cur.execute(phone_query, (phone,))
        phone_count = cur.fetchone()[0]

    email_query = "SELECT COUNT(*) FROM users WHERE email = %s"
    with conn.cursor() as cur:
        cur.execute(email_query, (email,))
        email_count = cur.fetchone()[0]
    if phone_count > 0 :
        return "Phone already exists!"
    elif email_count>0:
        return "Email already exists!"
    else:
        cur = conn.cursor()
    
    cur.execute(
        '''INSERT INTO users(created_time,email, name, phone, whatsapp_no,linkedin,designation,company,website,aboutCompany,lookingfor,sector,websiteReview,additionalInfo,category,typeofStartup,city,password,role,is_verified,verification_token,r_token,admin_approved,fcmtoken) VALUES (%s, %s, %s,%s, %s, %s, %s, %s,%s, %s,%s, %s, %s, %s,%s, %s, %s, %s, %s,%s, %s,%s,%s,%s)''',
        (datetime.now(),email,name,phone,whatsapp,linkedin,designation,company,website,abtCompany,lookingfor,sector,websiteReview,addInfo,category,typeofStartup,city,hashed_password.decode('utf-8'),role,"false",token,
         "","false",fcmtoken,))
    conn.commit()
    x=cur.rowcount
    cur.close()
    conn.close()
    if(x==1):
        email_server = 'smtp.gmail.com'
        email_port = 587
        email_username = 'nnagarithesh@gmail.com'
        email_password = 'euwdvgljzrsqviml'
        server = smtplib.SMTP(email_server, email_port)
        server.starttls()
        server.login(email_username, email_password)
        msg = MIMEMultipart()
        msg['From'] = 'nnagarithesh@gmail.com'
        msg['To'] = email
        msg['Subject'] = 'Email Verification'
        

        query_params = {
            'email': email,
            'token':token
        }
        query_string = urllib.parse.urlencode(query_params)
        base_url = 'http://165.232.176.210:5000/verify_email'
        verification_link = f"{base_url}?{query_string}"
        body = f"Dear {name},\n\nThank you for registering on our platform. Please click on the following link to verify your email: {verification_link}"

        msg.attach(MIMEText(body, 'plain'))
        server.sendmail(email_username, email, msg.as_string())
        server.quit()
        return 'Successfully Registered And mail sent!!!'
    else:
        return "Registration Failed!!"
@app.route("/verify_email",methods=['GET'])
def verified():
    reqtoken = request.args.get('token')
    reqemail = request.args.get('email')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    q = 'SELECT is_verified, verification_token FROM users WHERE email=%s'
    cur.execute(q, (reqemail,))
    result = cur.fetchone()
    if result is None:
        cur.close()  
        conn.close() 
        return "Email does not exist in the database."
    is_verified, verification_token = result
    if is_verified == 0:
        if reqtoken == verification_token:
            verifyemail = "UPDATE users SET is_verified='true' WHERE email=%s"
            cur.execute(verifyemail, (reqemail,))
            conn.commit()
            cur.execute('''INSERT INTO friends(user_email) VALUES(%s)''',(reqemail,));
            cur.execute('''INSERT INTO friend_request_notifications(user_email) VALUES(%s)''',(reqemail,));
            conn.commit()
            return "Email verified successfully"
            
        else:
            return "Email couldn't be verified"
    else:
       return "Email is already verified"
@app.route("/check_verified", methods=['POST'])
def check_verified():
    data=request.get_json()
    email = data.get('email')        
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("Select is_verified from users where email=%s",(email,))
    conn.commit()
    a=cur.fetchone()
    return str(a[0])

@app.route("/resend_email",methods=['POST'])
def resend():
    data=request.get_json()
    email = data.get('email')
    name = data.get('name')
    token = pbkdf2_sha256.hash(email)
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('UPDATE users set verification_token=%s where email=%s',(token,email,))
    conn.commit()
    email_server = 'smtp.gmail.com'
    email_port = 587
    email_username = 'nnagarithesh@gmail.com'
    email_password = 'euwdvgljzrsqviml'
    server = smtplib.SMTP(email_server, email_port)
    server.starttls()
    server.login(email_username, email_password)
    msg = MIMEMultipart()
    msg['From'] = 'nnagarithesh@gmail.com'
    msg['To'] = email
    msg['Subject'] = 'Email Verification'
        

    query_params = {
            'email': email,
            'token':token
    }
    query_string = urllib.parse.urlencode(query_params)
    base_url = 'http://165.232.176.210:5000/verify_email'
    verification_link = f"{base_url}?{query_string}"
    body = f"Dear {name},\n\nThank you for registering on our platform. Please click on the following link to verify your email: {verification_link}"

    msg.attach(MIMEText(body, 'plain'))
    server.sendmail(email_username, email, msg.as_string())
    server.quit()
    return 'Mail Sent!'
@app.route("/login",methods=['POST'])
def login():
    data=request.get_json()
    email = data.get('email')
    password = data.get('password')
    fcmtoken = data.get('fcmtoken')
    print(fcmtoken)
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("SELECT count(*) from users where email=%s",(email,))
    conn.commit()
    x=cur.fetchone()[0]
    print(x)
    if x == 1:
        cur.execute("SELECT * from users where email=%s", (email,))
        conn.commit()
        y = cur.fetchone()
        print(y)
        if y is not None:
            stored_hashed_password = y[18]
            if bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
                user_data_dict = {
                    "email": y[2],
                    "name": y[3],
                    "phone": y[4],
                    "whatsapp_no": y[5],
                    "linkedin": y[6],
                    "designation": y[7],
                    "company": y[8],
                    "website": y[9],
                    "aboutCompany": y[10],
                    "lookingfor": y[11],
                    "sector": y[12],
                    "websiteReview": y[13],
                    "additionalInfo": y[14],
                    "category": y[15],
                    "typeOfStartup": y[16],
                    "city": y[17],
                    "role": y[19],
                    "is_verified": y[20]
                }
                cur.execute("UPDATE users set fcmtoken=%s where email=%s",(fcmtoken,email,))
                conn.commit()
                return(jsonify(user_data_dict))
            else:
                    return "Password is incorrect"
        else:
            return "Email doesn't exist!!"
    else:
        return "Email doesn't exist!!"
@app.route("/resetpassmail",methods=['POST'])
def mailpass():
    data=request.get_json()
    email = data.get('email')
    email_server = 'smtp.gmail.com'
    email_port = 587
    email_username = 'nnagarithesh@gmail.com'
    email_password = 'euwdvgljzrsqviml'
    server = smtplib.SMTP(email_server, email_port)
    server.starttls()
    rtoken = pbkdf2_sha256.hash(email)
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('UPDATE users set r_token=%s where email=%s',(rtoken,email,))
    conn.commit()
    server.login(email_username, email_password)
    msg = MIMEMultipart()
    msg['From'] = 'nnagarithesh@gmail.com'
    msg['To'] = email
    msg['Subject'] = 'Reset Password'
    cur.execute("Select count(*) from users where email=%s",(email,))
    res = cur.fetchone()
    if str(res[0]) == "0":
        return "Email is not registered"
    else:
        cur.execute("Select name from users where email=%s",(email,))
        name=cur.fetchone()[0]
        query_params = {
                'email': email,
                'token':rtoken
        }
        query_string = urllib.parse.urlencode(query_params)
        base_url = 'http://165.232.176.210:5000/reset_pass'
        reset_pass_link = f"{base_url}?{query_string}"
        body = f"Dear {name},\n\nYou have requested to reset your password. Please click on the following link to reset your password: {reset_pass_link}"

        msg.attach(MIMEText(body, 'plain'))
        server.sendmail(email_username, email, msg.as_string())
        server.quit()
        return 'Mail Sent!'
@app.route("/friend_request",methods=['POST'])
def frnd_req():
    data=request.get_json()
    email = data.get('email')
    frndemail = data.get('frnd_email')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("SELECT admin_approved FROM users WHERE email = %s", (email,))
    b = cur.fetchone()[0]
    
    if b==True:
        cur.execute("Select count(*) from friends where user_email = %s and %s = ANY(requested_friends)",(email, frndemail,))
        ans = cur.fetchone()[0]
        if(ans == 0):
            cur.execute("Update friends set requested_friends=requested_friends||%s where user_email = %s",([frndemail],email,));
            cur.execute("Update friends set pending_friends=pending_friends||%s where user_email =%s",([email],frndemail,));
            cur.execute('Select fcmtoken,name from users where email=%s',(frndemail,))
            conn.commit()
            
            data=cur.fetchall()[0]
            token = data[0]
            name=data[1]
            print(token)
            print(name)
            cur.execute("Select name from users where email=%s",(email,))
            conn.commit()
            a=cur.fetchall()[0][0]
            serverToken = 'AAAAXnMn4CM:APA91bGZIaLqHHYcbBws-An7JD9ozGdby60ChWv-0Tn0psxxDYMeC0J47VhIwjF8R1cOSNn2KnFFCAz314sC38tiS_Ckk2SfZD7U79oFalAjTIxF2hmb5MeMzi5JSZ9agWwA_qoh6B8f'
            deviceToken = token;
            headers = {
                'Content-Type': 'application/json',
                'Authorization': 'key=' + serverToken,
            }
            body = {
                'notification': {'title': f'Dear {name}, you have a new friend request',
                                    'body': f'{a} has requested to follow you',
                                    },
                'to':
                    deviceToken,
                'priority': 'high',
                
            }
            cur.execute("Update friend_request_notifications set notification_body=notification_body||%s where user_email=%s",([f'{a} has requested to follow you'],frndemail))
            conn.commit()
            response = requests.post("https://fcm.googleapis.com/fcm/send",headers = headers, data=json.dumps(body))
            print(response.status_code)
            print(response.json())
            return "Friend Request Sent!!"
        else:
            return "Requested already!!"
    else:
        print("Admin approval is pending!!")
        return "Admin approval is pending!!"
@app.route("/fetchpendingfriends", methods=['POST'])
def fetchpendingfriends():
    data=request.get_json()
    email = data.get('email')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("Select pending_friends from friends where user_email=%s",(email,))
    res1 = cur.fetchone()[0]
    print(res1)
    return res1
@app.route("/cancelrequest",methods=['POST'])
def cancelrequest():
    data=request.get_json()
    email = data.get('email')
    frndemail = data.get('frnd_email')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("SELECT requested_friends FROM friends WHERE user_email = %s", (email,))    
    requested_friend_list = cur.fetchone()[0]
    rindex = requested_friend_list.index(frndemail)
    requested_friend_list.pop(rindex)
    cur.execute("SELECT pending_friends FROM friends WHERE user_email = %s", (frndemail,))    
    pening_friends_list = cur.fetchone()[0]
    pindex = pening_friends_list.index(email)
    pening_friends_list.pop(pindex)
    cur.execute("select notification_body from friend_request_notifications where user_email = %s",(frndemail,))
    pending_notif_list = cur.fetchone()[0]
    pending_notif_list.pop(pindex)
    cur.execute("UPDATE friends SET pending_friends = %s WHERE user_email = %s", (pening_friends_list, frndemail))
    cur.execute("UPDATE friends SET requested_friends = %s WHERE user_email = %s", (requested_friend_list, email))
    cur.execute("UPDATE friend_request_notifications SET notification_body = %s WHERE user_email = %s", (pending_notif_list, frndemail))
    conn.commit()
    return "Success"
@app.route("/getnumberofnotifs", methods=['POST'])
def getnumber():
    data = request.get_json()
    email = data.get('email')
    conn = psycopg2.connect(
        database="startup_ignition",
        user="rithesh",
        password="StartUpIgnition",
        host="localhost",
        port="5432"
    )
    cur = conn.cursor()
    cur.execute(
        "SELECT COUNT(*) FROM friend_request_notifications WHERE user_email=%s AND notification_body IS NOT NULL AND notification_body != '{}'",
        (email,)
    )
    count = cur.fetchone()[0] 
    print(count)
    return str(count)
@app.route("/acceptfriend", methods=['POST'])
def accept():
    data=request.get_json()
    email = data.get('email')
    frndemail = data.get('frnd_email')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("SELECT pending_friends FROM friends WHERE user_email = %s", (email,))    
    pending_friends_list = cur.fetchone()[0]
    index = pending_friends_list.index(frndemail)

    print(index)
    cur.execute("select notification_body from friend_request_notifications where user_email = %s",(email,))
    pending_notif_list = cur.fetchone()[0]
    pending_notif_list.pop(index)
    removed_item = pending_friends_list.pop(index)
    cur.execute("UPDATE friends SET pending_friends = %s WHERE user_email = %s", (pending_friends_list, email))
    cur.execute("UPDATE friend_request_notifications SET notification_body = %s WHERE user_email = %s", (pending_notif_list, email))
    cur.execute("SELECT requested_friends FROM friends WHERE user_email = %s", (removed_item,))
    requested_friendslist = cur.fetchone()[0]
    requested_friendslist.remove(email)
    cur.execute("UPDATE friends SET requested_friends = %s WHERE user_email = %s", (requested_friendslist, removed_item))
    cur.execute("Update friends set friends=friends||%s where user_email =%s",([removed_item],email,))
    cur.execute("Update friends set friends=friends||%s where user_email =%s",([email],removed_item,))
    conn.commit()
    return "Success"
    
@app.route("/checkfriendStatus", methods=['POST'])
def checkfrndStatus():
    data=request.get_json()
    email = data.get('email')
    frndemail = data.get('frnd_email')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("Select requested_friends from friends where user_email=%s",(email,))
    result = cur.fetchone()
    cur.execute("Select friends from friends where user_email=%s",(email,))
    res = cur.fetchone()
    
    conn.close()
    requested_friend = result[0]
    friends = res[0]
    
    if requested_friend:
        if frndemail in requested_friend:
            print("there")
            return "00"
        else:
            if friends:
                if frndemail in friends:
                    print("frnd there")
                    return "0"
                else:
                    print("both not there")
                    return "1"
            else:
                    print("both not there")
                    return "1"
    else:
        if friends:
                if frndemail in friends:
                    print("frnd there")
                    return "0"
                else:
                    print("both not there")
                    return "1"
        else:
                    print("both not there")
                    return "1"
    
    
    
    
@app.route("/reset_pass")
def resetpass():
    reqemail = request.args.get('email')
    reqrtoken = request.args.get('token')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('Select count(*) from users where email=%s',(reqemail,))
    a=cur.fetchone()
    conn.commit()
    if a is not None:
        cur.execute('Select r_token from users where email = %s',(reqemail,))
        res=cur.fetchone()[0]
        print(res)
        print(reqrtoken)
        conn.commit()
        if res == reqrtoken:
            return render_template("forgot.html")
        else:
            return "Invalid Link"
    else:
        return  "Email doesnt exist"
@app.route("/adminlogincheck", methods=['POST'])
def logincheck():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()

    email = request.form.get("email")
    password = request.form.get("password")
    cur.execute("Select email, password from admin where id=1")
    res=cur.fetchone()
    e=res[0]
    p=res[1]
    if(password == p and email == e):
        message="Login Success"
        
    else:
        message= "Login Failed"
    return render_template("admin_login.html", message=message)

@app.route("/admin_login", methods=['GET'])
def adminlogin():
    return render_template("admin_login.html")
@app.route("/admin_dashboard", methods=['GET'])
def admindashboard():
    return render_template("admin_dashboard.html")
@app.route("/fetch", methods=['GET'])
def fetch():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('Select name,email, role, company, designation from users where is_verified = true and admin_approved=false')
    result = cur.fetchall()
    print(jsonify(result))
    return jsonify(result)
@app.route("/update_status",methods=['POST'])
def updatestatus():
    data = request.get_json()
    email = data.get('item_email')
    
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("UPDATE users set admin_approved='t' where email = %s",(email,))
    conn.commit()
    print("Done")
    return "Admin Approved"
@app.route("/updateData",methods=['POST'])
def updateData():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    role = data.get('role')
    whatsapp = data.get('whatsapp_no')
    linkedin = data.get('linkedin')
    designation = data.get('designation')
    company = data.get('company')
    website = data.get('website')
    abtCompany = data.get('aboutCompany')
    lookingfor = data.get('lookingfor')
    sector = data.get('sector')
    websiteReview = data.get('websiteReview')
    addInfo = data.get('additionalInfo')
    category = data.get('category')
    typeofStartup = data.get('typeOfStartup')
    city = data.get('city')
    
    
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("""UPDATE users
        SET
            name = %s,
            phone = %s,
            role = %s,
            whatsapp_no = %s,
            linkedin = %s,
            designation = %s,
            company = %s,
            website = %s,
            aboutCompany = %s,
            lookingfor = %s,
            sector = %s,
            websiteReview = %s,
            additionalInfo = %s,
            category = %s,
            typeOfStartup = %s,
            city = %s
        WHERE
            email = %s;
        """,
        (
            name,  phone, role, whatsapp, linkedin,
            designation, company, website, abtCompany, lookingfor,
            sector, websiteReview, addInfo, category, typeofStartup,
            city, email
        )
        )
    conn.commit()
    
    return "Updated Successfully!!"
@app.route("/getusers",methods=['GET'])
def getusers():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("select name , email , designation ,website,company,city from users where admin_approved=true")
    conn.commit()
    result = cur.fetchall()
    print(result)
    return result
@app.route("/fetchnotifs",methods=['POST'])
def getnotifs():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    data = request.get_json()
    email = data.get('email')
    cur = conn.cursor()
    cur.execute("select notification_body from friend_request_notifications where user_email = %s",(email,))
    conn.commit()
    result = cur.fetchall()[0][0]
    print(result)
    return result
@app.route("/friendaction",methods=['POST'])
def friendaction():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    data = request.get_json()
    email = data.get('email')
    action = data.get('action')
    i = data.get('itemIndex')
    cur = conn.cursor()
    cur.execute("SELECT pending_friends FROM friends WHERE user_email = %s", (email,))    
    pending_friends_list = cur.fetchone()[0]
    cur.execute("select notification_body from friend_request_notifications where user_email = %s",(email,))
    pending_notif_list = cur.fetchone()[0]
    cur.execute("SELECT  FROM friends WHERE user_email = %s", (email,)) 
    if(action == "accept"):
        if pending_friends_list:  
                if i < len(pending_friends_list):
                    removed_item = pending_friends_list.pop(i)
                    pending_notif_list.pop(i)
                    cur.execute("UPDATE friends SET pending_friends = %s WHERE user_email = %s", (pending_friends_list, email))
                    cur.execute("UPDATE friend_request_notifications SET notification_body = %s WHERE user_email = %s", (pending_notif_list, email))
                    cur.execute("SELECT requested_friends FROM friends WHERE user_email = %s", (removed_item,))
                    requested_friendslist = cur.fetchone()[0]
                    requested_friendslist.remove(email)
                    cur.execute("UPDATE friends SET requested_friends = %s WHERE user_email = %s", (requested_friendslist, removed_item))
                    cur.execute("Update friends set friends=friends||%s where user_email =%s",([removed_item],email,));
                    cur.execute("Update friends set friends=friends||%s where user_email =%s",([email],removed_item,));
                    conn.commit()
                    
                    result = f"Removed {removed_item} from pending_friends and updated in the database"
                else:
                    result = "Index out of range"
        else:
            result = "No pending friends to process"
    else:
        if pending_friends_list:  
                if i < len(pending_friends_list):
                    removed_item = pending_friends_list.pop(i)
                    pending_notif_list.pop(i)   
                    cur.execute("UPDATE friends SET pending_friends = %s WHERE user_email = %s", (pending_friends_list, email))
                    cur.execute("UPDATE friend_request_notifications SET notification_body = %s WHERE user_email = %s", (pending_notif_list, email))
                    cur.execute("SELECT requested_friends FROM friends WHERE user_email = %s", (removed_item,))
                    requested_friendslist = cur.fetchone()[0]
                    requested_friendslist.remove(email)
                    cur.execute("UPDATE friends SET requested_friends = %s WHERE user_email = %s", (requested_friendslist, removed_item))
                    conn.commit() 
                    result = f"Removed {removed_item} from pending_friends and updated in the database"
                else:
                    result = "Index out of range"
        else:
            result = "No pending friends to process"    
    print(result)
    return result
@app.route("/completed")
def completed():
    return "Password Updated"    
@app.route("/reseting_pass",methods=['POST'])
def reseting_pass():
    data = request.get_json()
    pswd = data.get('pass')
    email = data.get('email')
    hashed_password = bcrypt.hashpw(pswd.encode('utf-8'), bcrypt.gensalt())
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('Update users set password = %s where email=%s',(hashed_password.decode('utf-8'),email,))
    conn.commit()
    print("Pass updated")
    cur.execute("Update users set r_token='' where email=%s",(email,))
    conn.commit()
    return "Password Updated!!"

@app.route("/successstory",methods=['POST'])
def successstory():
    postdata = request.get_json()
    successStory=postdata.get("successStory")
    amount= postdata.get('amount')
    partnerNames=postdata.get('partnerNames')
    phone=postdata.get('mobile')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    
    cur.execute('''INSERT INTO story(created_time,successStory,amount,partnerNames,phone) VALUES(%s,%s, %s, %s,%s)''',
                (datetime.now(),successStory,amount,partnerNames,phone))
    conn.commit()
    x=cur.rowcount
    cur.close()
    conn.close()
    if(x==1):
        return 'Successfully Posted!!!'
    else:
        return "Post couldn't be uploaded!!"
@app.route("/deletestory",methods=['POST'])
def deletestory():
    postdata = request.get_json()
    successStory=postdata.get("successStory")
    amount= postdata.get('amount')
    partnerNames=postdata.get('partnerNames')
    phone=postdata.get('mobile')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    
    cur.execute('''DELETE from story where phone = %s''',(phone,))
    conn.commit()
    x=cur.rowcount
    cur.close()
    conn.close()
    return x;
@app.route("/getstories",methods=['GET'])
def getpost():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute("SELECT * from story ORDER BY created_time DESC LIMIT 10")
    rows = cur.fetchall()
    return jsonify(rows)
@app.route("/postjob",methods=['POST'])
def postjob():
    data = request.get_json()
    title= data.get('title')
    c_name= data.get('companyName')
    email= data.get('email')
    imgurl= data.get('imageUrl')
    content= data.get('content')
    tags= data.get('tags')
    comments = data.get('comments')
    contentCoverUrl = data.get('contentCoverUrl')
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('''INSERT INTO jobs(title,c_name,email,imgurl,content,tags,comments,ccu) VALUES(%s,%s,%s, %s, %s, %s, %s,%s)''',
                (title,c_name,email,imgurl,content,tags,comments,contentCoverUrl))
    conn.commit()
    x=cur.rowcount
    cur.close()
    conn.close()
    if(x==1):
        return 'Job posted!!!'
    else:
        return "Job Post couldn't be uploaded!!"


@app.route("/getjobs",methods=['GET'])
def getjobs():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('''SELECT * from jobs''')
    rows = cur.fetchall()
    list=[]
    for a in rows:
        list.append(a)
    conn.close()
    print(jsonify(list))
    return jsonify(list)
    
@app.route("/startup",methods=['POST'])
def startup():
    data = request.get_json()
    c_name=  data.get('companyName')
    c_desc=data.get('companyDescription')
    c_stats= data.get('companyStats')
    c_imgurl= data.get('companyIconUrl')
    carouselList= data.get('carouselList')
    c_value= data.get('companyValue')
    
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('''INSERT INTO startup(c_name,c_desc,c_stats,c_imgurl,carouselList,c_value) VALUES(%s,%s,%s, %s, %s, %s)''',
                (c_name,c_desc,c_stats,c_imgurl,carouselList,c_value))
    conn.commit()
    x=cur.rowcount
    cur.close()
    conn.close()
    if(x==1):
        return 'Company created!!!'
    else:
        return "Company couldn't be created!!"
    
@app.route("/getstartups",methods=['GET'])
def getstartups():
    conn = psycopg2.connect(database="startup_ignition",
                            user="rithesh",
                            password="StartUpIgnition",
                            host="localhost", port="5432")
    cur = conn.cursor()
    cur.execute('''SELECT * from startup''')
    rows = cur.fetchall()
    list=[]
    for a in rows:
        list.append(a)
    conn.close()
    print(jsonify(list))
    return jsonify(list)
@app.route("/test", methods=['GET']) 
def test():
    print("test")
    return "test"
if __name__ == '__main__':
	app.run(debug=True, port=5000, host='0.0.0.0')

