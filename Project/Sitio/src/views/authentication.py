from .libraries import *

def loggedInUser():
    return "user" in session and session["user"] and type(session["user"])==type('')

def loggedInClient():
    return loggedInUser() and not ("isAdmin" in session and session["isAdmin"])

def loggedInAdmin():
    return loggedInUser() and "isAdmin" in session and session["isAdmin"]

def getMessage():
    message = "" if "message" not in session else session["message"]
    session["message"] = ""
    return message

@app.route("/logOut")
def logOut():
    session["id"] = 0
    session["user"] = ""
    session["message"] = "Logged out"
    return redirect(url_for(".index"))


def get_auth():
    return {
        "clientLogged": loggedInClient(),
        "adminLogged": loggedInAdmin(),
        "message": getMessage()
    }