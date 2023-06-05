from .libraries import *
from .authentication import *

@app.route("/admin")
def adminHome():
    return render_template("admin.html", auth=get_auth())

@app.route("/admin/consult")
def adminConsult():
    return render_template("admin-consult.html", auth=get_auth())

@app.route("/admin/consult/products", methods=["GET", "POST"])
def adminConsultProducts():
    query = "productsConsult"
    if request.method=="POST":
        type = request.form["types"]
        amount = request.form["amount"]
        sold = request.form["sold"]
        if amount == "":
            amount = "NULL"
        if sold == "":
            sold = "NULL"
        query = "productsConsult "+str(type)+", "+str(amount)+", "+str(sold)

    information = dataBaseQuery(query)
    types = dataBaseQuery("getTypes")
    return render_template("admin-consult-products.html", auth=get_auth(), whiskys = information, types = types)

@app.route("/admin/consult/products/purchases", methods=["GET", "POST"])
def adminConsultClient():
    query = "purchasesConsult"
    if request.method=="POST":
        country = request.form["types"]
        date1 = request.form["date1"]
        date2 = request.form["date2"]
        query = "purchasesConsult '"+str(country)+"', '"+str(date1)+"', '"+str(date2)+"'"
    print(query)
    information = dataBaseQuery(query)
    return render_template("admin-consult-purchases.html", auth=get_auth(), whiskys = information)

