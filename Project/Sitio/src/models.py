import pyodbc
import MySQLdb
from flask_mysqldb import MySQL
import mysql.connector

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import DATABASEENVIROMENT as DBE
# DESKTOP-94UDDNK


def dataBaseQuery(consult):
    server = DBE.SQLSERVER_SERVER
    database = 'MasterBase'
    username = DBE.SQLSERVER_USERNAME
    password = DBE.SQLSERVER_PASSWORD
    conexion = pyodbc.connect(
        'DRIVER={SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD=' + password)
    cursor = conexion.cursor()
    cursor.execute(consult)
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    cursor.commit()
    cursor.close()
    conexion.close()

    return data


def dataBaseQueryUSA(consult):
    server = DBE.SQLSERVER_SERVER
    database = 'USA'
    username = DBE.SQLSERVER_USERNAME
    password = DBE.SQLSERVER_PASSWORD
    conexion = pyodbc.connect(
        'DRIVER={SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD=' + password)
    cursor = conexion.cursor()
    cursor.execute(consult)
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    cursor.commit()
    cursor.close()
    conexion.close()

    return data


def dataBaseQueryScotland(consult):
    server = DBE.SQLSERVER_SERVER
    database = 'Scotland'
    username = DBE.SQLSERVER_USERNAME
    password = DBE.SQLSERVER_PASSWORD
    conexion = pyodbc.connect(
        'DRIVER={SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD=' + password)
    cursor = conexion.cursor()
    cursor.execute(consult)
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    cursor.commit()
    cursor.close()
    conexion.close()

    return data


def dataBaseQueryIreland(consult):
    server = DBE.SQLSERVER_SERVER
    database = 'Ireland'
    username = DBE.SQLSERVER_USERNAME
    password = DBE.SQLSERVER_PASSWORD
    conexion = pyodbc.connect(
        'DRIVER={SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD=' + password)
    cursor = conexion.cursor()
    cursor.execute(consult)
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    cursor.commit()
    cursor.close()
    conexion.close()

    return data


def dataBaseQueryUsersMysql(query):

    mysql = MySQLdb.connect(host=DBE.MYSQL_SERVER, user=DBE.MYSQL_USERNAME,
                            passwd=DBE.MYSQL_PASSWORD, db='user')
    cursor = mysql.cursor()
    cursor.callproc(query)
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    mysql.close()
    return data


def dataBaseQueryEmployeesMysql(name, adress, ident, phone, email, in_shop, country, salary, id_pos):

    mysql = MySQLdb.connect(host=DBE.MYSQL_SERVER, user=DBE.MYSQL_USERNAME,
                            passwd=DBE.MYSQL_PASSWORD, db='employee')
    cursor = mysql.cursor()
    cursor.callproc("InsertEmployee", [
                    name, adress, ident, phone, email, in_shop, country, salary, id_pos])
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    mysql.close()
    return data


def dataBaseQueryEmployeesUpdateMysql(name, adress, ident, phone, email, salary, id_pos):

    mysql = MySQLdb.connect(host=DBE.MYSQL_SERVER, user=DBE.MYSQL_USERNAME,
                            passwd=DBE.MYSQL_PASSWORD, db='employee')
    cursor = mysql.cursor()
    cursor.callproc("ModifyEmployee", [
                    name, adress, ident, phone, email, salary, id_pos])
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    mysql.close()
    return data


def dataBaseQueryMysqlReview(user_ident, employee_id, review, calification):

    mysql = MySQLdb.connect(host=DBE.MYSQL_SERVER, user=DBE.MYSQL_USERNAME,
                            passwd=DBE.MYSQL_PASSWORD, db='employee')
    cursor = mysql.cursor()
    cursor.callproc("InsertEmployeeReview", [
                    user_ident, employee_id, review, calification])
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    mysql.close()
    return data


def dataBaseQueryEmployeesDeleteMysql(ident):

    mysql = MySQLdb.connect(host=DBE.MYSQL_SERVER, user=DBE.MYSQL_USERNAME,
                            passwd=DBE.MYSQL_PASSWORD, db='employee')
    cursor = mysql.cursor()
    cursor.callproc("DeleteEmployee", [ident])
    data = []
    try:
        for i in cursor:
            data += [i]

    except:
        pass
    mysql.close()
    return data


def MysqlUsers(name, adress, id, phone, email):
    connection = mysql.connector.connect(
        host=DBE.MYSQL_SERVER, database='user', user=DBE.MYSQL_USERNAME, password=DBE.MYSQL_PASSWORD)
    cursor = connection.cursor()
    cursor.callproc("InsertClient", [name, adress, id, phone, email])
    data = []
    for result in cursor.stored_results():
        data += result.fetchall()

    cursor.close()
    connection.close()
    return data[0][0]
