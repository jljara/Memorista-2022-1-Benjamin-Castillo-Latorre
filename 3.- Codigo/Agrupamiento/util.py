from multiprocessing.connection import wait
import time
#Funcion que añade comillas simples ('') a un string
#Entrada: un string
#Salida: un string
def add_quotes_to_string(string):
    #si es un string vacio, lo retorna
    if(not string):
        return  string
    #Si no es vacio, lo entrega con comillas
    else:
        return repr(string)

#Funcion que verifica si un string es vacio
#Entrada: un string
#Salida: un booleano
def string_is_empty(string):
    if(string):
        return False
    else:
        return True

def concat_names(names, surname1,surname2):
    return names + " " + surname1 + " " + surname2

def strings_should_be_equal(string1,string2):
    return string1 == string2

def generate_group_text(group):
    group = str(group).strip("''")
    return "'Miembros de: " + group + "'"

def concat_strings(string1,string2):
    return  string1 + string2
    
def wait_seconds(seconds):
    seconds = float(seconds)
    time.sleep(seconds)

def get_position_in_table(position):
    path = 'xpath://tr[' + str(position) + ']/td[4]/a[3]'
    return path

def capitalize_string(string):
    string = string.capitalize()
    return string

def upcase_string(string):
    string = string.upper()
    return string

def lowercase_string(string):
    string = string.lower()
    return string

def is_upcase_string(string):
    return string.isupper()

def is_lowercase_string(string):
    return string.islower()