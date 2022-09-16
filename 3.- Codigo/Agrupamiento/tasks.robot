
#TODO
#Generar un archivo que te diga que alumnos fueron agregados

*** Settings ***
Documentation     Template robot main suite.
Library    RPA.Dialogs
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Excel.Files
Library    util.py
Library    RPA.Desktop


*** Variables ***
#Agrupamiento/devdata/Grupos.xlsx
${EXCEL}    devdata/Grupos.xlsx
${USUARIO}    %{USUARIO_PROFESOR}
${PASSWORD}   %{PASSWORD}
${ASIGNATURA}    %{ASIGNATURA}

*** Keywords ***
#Este proceso no ingresa el captcha si no que le pide al usuario ingresarlo
#Una vez se cierra sigue el proceso
Ingresar Captcha
    Add icon      Warning
    Add heading   Por favor verifique que es humano para seguir con el proceso y luego haga click en close para continuar
    Run dialog    title=Rellene el captcha    height=350    width=512
    
Ingresar Datos
    Add icon      Warning
    Add heading   Por favor inicie sesion y aprete el boton close una vez haya cargado la pagina
    Run dialog    title=Rellene su informacion    height=350    width=512
#Inicia sesion en la plataforma de UVirtual
Iniciar Sesion
    Input Text    username    ${USUARIO}
    Input Password    password    ${PASSWORD}
    Click Button When Visible    loginbtn

#Ingresa a la plataforma de UVirtual
Abrir UVirtual
    Open Available Browser    https://uvirtual.usach.cl/moodle/init/
    Maximize Browser Window
    #Verifica si
    ${captcha_existe}         Does Page Contain    Estamos verificando que no sea un BOT...
    IF    ${captcha_existe} 
        Ingresar Captcha        
    END
    ${login}    Does Page Contain    Acceda a su cuenta 
    ${usuarioVacio}    String Is Empty    ${USUARIO}
    ${contraseñaVacia}    String Is Empty    ${PASSWORD}

    IF    ${login}
        IF    ${usuarioVacio} == True or ${contraseñaVacia} == True
            Ingresar Datos
        ELSE
            Iniciar Sesion
        END
    END
    Wait Until Page Contains    Mis Cursos    1 min

#Interfaz que se muestra cuando no se logra encontrar el curso
Interfaz Seleccionar Curso
    Add icon      Warning
    Add heading   El robot no ha logrado encontrar el curso, por favor haga click al curso que desea en el que trabaje, espere a que cargue la pagina y luego haga click en Close
    Run dialog    title=Seleccione el curso    height=350    width=512

#Selecciona el curso al que se quiere crear grupos/secciones
Seleccionar Curso
    ${string_vacio}    String Is Empty    ${ASIGNATURA}
    #Verifica si el bot encontro el curso
    ${curso_existe}    Does Page Contain    ${ASIGNATURA}
    #Si existe le hace click
    IF    ${string_vacio}
        Interfaz Seleccionar Curso
    ELSE IF    ${curso_existe}
        Click Link    ${ASIGNATURA}  
    #Si no existe muestra una interfaz
    ELSE
        Interfaz Seleccionar Curso
    END
    #Espera a que cargue el curso
    Wait Until Page Contains Element    id:region-main-box    1 min

#Abre el menu lateral en caso de que este cerrado
Abrir Menu
    #Verifica si el menu esta cerrado
    ${menu}    Does Page Contain Element    class:is-active
    #Si esta cerrado lo abre
    IF    ${menu} == False
        Click Button    class:float-sm-left
    END
    #Espera a que abra el menu
    Wait Until Element Is Visible    link:Calificaciones    1 min

#Va a la seccion de participantes del menu lateral
Ir a Participantes
    #Le hace click a participantes y espera a que cargue la pagina
    Click Element    xpath://span[contains(.,'Participantes')]
    Wait Until Page Contains    Participantes    1 min

#Va a la seccion de grupos
Ir a Seccion Grupos
    #Le hace click a la ruedita, luego a grupos y espera a que cargue la pagina
    Click Element When Visible    id:dropdown-3
    Click Element When Visible    link:Grupos
    Wait Until Page Contains Element    id:members    1 min

#Va a la seccion de agrupamientos
Ir a Agrupamientos
    #Le hace click a agrupamientos
    #Lo cambiaste de if a when el 22/04/22 a las 09:21
    Click Element When Visible    link:Agrupamientos
    Wait Until Page Contains    Agrupamiento

#Funcion que agrega un alumno
#Entrada: Un row del archivo que representa a un alumno
                      #apellidos
#Formato: Nombres Paterno Materno Correo Grupo         
Agregar alumno
    [Arguments]    ${alumno}
    #Concatena los nombres con los apellidos del alumno
    ${nombre}    Concat Names    ${alumno}[Nombres]    ${alumno}[Paterno]    ${alumno}[Materno]
    #Le añade comillas simples al nombre para poder buscarlo en la pagina
    ${nombre}    Add Quotes To String    ${nombre}
    #Le añade comillas simples al correo para poder buscarlo en la pagina
    ${correo}    Add Quotes To String    ${alumno}[Correo]
    #Se debe verificar si el nombre esta, si no se debe ver si el correo existe
    ${nombreDetectado}    Does Page Contain Element    xpath://option[contains(.,${nombre})]
    ${emailDetectado}    Does Page Contain Element    xpath://option[contains(.,${correo})]
    #Si detecto el nombre
    IF    ${nombreDetectado} == True
        #Le hace click
        Click Element    xpath://option[contains(.,${nombre})]
        #Ve si esta en la zona de no agregados
        ${agregar}    Is Element Enabled    id:add
        IF    ${agregar}
            #lo agrega
            Click Button    id:add
            Log    agregado
        #Si ya esta agregado
        ELSE
            Log    ya estaba
        END
    #Si detecta el email
    ELSE IF    ${emailDetectado} == True
        Click Element    xpath://option[contains(.,${correo})]
        #verifica si esta en la zona de no agregados
        ${agregar}    Is Element Enabled    id:add
        IF    ${agregar}
            Click Button    id:add
            Log    agregado
        #Si ya esta agregado
        ELSE
            Log    ya estaba
        END
    #Si no lo detecta
    ELSE
        Log    no agregado
    END
    #Vuelve a la zona anterior
    Click Button    name:cancel
    Wait Until Page Contains Element    id:memberslabel    1 min


#Funcion que agrega los alumnos leyendo un archivo excel
Agregar alumnos
    #Select From List By Value    //div[@id='removeselect_wrapper']/select    Alejandra
    #Abre el excel y selecciona la hoja de alumnos
    Open Workbook    ${EXCEL}
    #Selecciona la hoja alumnos
    Set active worksheet    Alumnos
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    #Para cada fila de la hoja (alumno)
    FOR    ${alumno}    IN    @{archivo}
        #Verifica si el grupo ha sido creado
        ${grupoExiste}    Does Page Contain    ${alumno}[Grupo]
        ${grupo}    Add Quotes To String    ${alumno}[Grupo]
        #Si el grupo ha sido creado
        IF    ${grupoExiste} == True
            #Hace click en el grupo
            Click Element    xpath://option[contains(.,${grupo})]
            #Variable que crea un texto con el siguiente formato Miembros de: Grupo N para
            #verificar que se cargaron los alumnos del grupo
            ${texto}    Generate Group Text    ${grupo}
            #Obtiene el nombre del alumno
            ${nombre}    Concat Names    ${alumno}[Nombres]    ${alumno}[Paterno]    ${alumno}[Materno]
            ${nombre}    Add Quotes To String    ${nombre}
            #Espera 0.5 segundos para que carguen los alumnos
            #Wait Until Page Contains Element    xpath://span[contains(.,${texto})] 
            Wait Seconds    0.5
            #Ve si el alumno esta en el grupo seleccionado
            ${alumnoAgregado}    Does Page Contain Element    xpath://option[contains(.,${nombre})]
            #Si el alumno no esta agregado, lo agrega
            IF    ${alumnoAgregado} == False
                #Click en agregar
                Click Button    id:showaddmembersform
                #Espera a que cargue la pagina
                Wait Until Element Is Visible    xpath://label[contains(.,'Miembros del grupo')]    1 min   
                Agregar alumno    ${alumno}
            #Si el alumno ya estaba agregado
            ELSE
                Log    ya estaba agregado
            END
            #Le hace click ya que despues de agregarlo (o en caso de que no se agregue)
            #sigue seleccionado
            Click Element    xpath://option[contains(.,${grupo})]
        END
    END

#Funcion que crea un grupo
#Entrada: un row del archivo excel que representa a un grupo
Crear Grupo
    [Arguments]    ${grupo}
    #Ve si el grupo ya fue creado
    ${existeGrupo}    Does Page Contain    ${grupo}[Grupo]
    #Le añade comillas simples para seleccionarlo
    ${grupoSeleccion}    Add Quotes To String    ${grupo}[Grupo]
    #Si no ha sido creado, lo crea
    IF    ${existeGrupo} == ${False}
        #Va a la seccion de crear grupo y espera a que cargue
        Click Element    id:showcreateorphangroupform
        Wait Until Page Contains Element    id:id_name
        #Ingresa el nombre del grupo y crea el grupo
        Input Text    id:id_name    ${grupo}[Grupo]
        Click Button    id:id_submitbutton
        #Espera a que cargue la pagina
        Wait Until Page Contains Element    id:members    1 min
        #Le hace click al grupo para deseleccionarlo
        Click Element    xpath://option[contains(.,${grupoSeleccion})]
    END  
        
#Funcion que crea los grupos dado un archivo excel
Crear Grupos
    #Abre el archivo excel que contiene los grupos
    Open Workbook    ${EXCEL}
    #Selecciona la hoja de grupos
    Set active worksheet    Grupos
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    #Para cada grupo en el archivo, crea un grupo
    FOR    ${grupo}    IN    @{archivo}
        Crear Grupo    ${grupo}
    END

#Funcion que crea un agrupamiento
#Entrada: Una row de un archivo excel que representa a una seccion
Crear Agrupamiento
    [Arguments]    ${seccion}
    #Le añade comillas simples al nombre de la seccion
    ${nombreSeccion}    Add Quotes To String    ${seccion}[Seccion]
    #Verifica si la seccion fue creada
    ${seccionCreada}    Does Page Contain Element    xpath://td[contains(.,${nombreSeccion})]
    #Si no fue creada, la crea
    IF    ${seccionCreada} == False
        #Hace click en crear agrupamiento y espera a que cargue
        Click Button    xpath://form/button
        Wait Until Page Contains Element    id:id_name
        #Ingresa el nombre de la seccion y la crea
        Input Text    id:id_name    ${seccion}[Seccion]
        Click Button    id:id_submitbutton
        #Espera a que cargue la seccion
        Wait Until Page Contains    Agrupamientos
    #Si no fue creada
    ELSE
        Log    A
    END
    #Return de prueba
    [Return]    "hola"

#Funcion que crea las secciones dado un archivo excel
Crear Agrupamientos
    #Lee el archivo excel y obtiene las secciones
    Open Workbook    ${EXCEL}
    #Abre la hoja Secciones
    Set active worksheet    Secciones
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    #Crea cada seccion en el archivo
    FOR    ${seccion}    IN    @{archivo}
        #Test de return
        ${pepe}    Crear Agrupamiento    ${seccion}
    END
    
#//section[@id='region-main']/div/table/tbody/tr[2]/td[4]/a[3]/i
Agregar Grupo a Seccion
    [Arguments]    ${grupo}
    ${grupo}    Add Quotes To String    ${grupo}
    ${grupoExiste}    Does Page Contain Element    xpath://option[contains(.,${grupo})]
    IF    ${grupoExiste} == True
        Click Element    xpath://option[contains(.,${grupo})]
        ${botonHabilitado}    Is Element Enabled    name:add
        #Si esta el boton agregar esta habilitado (esta a la derecha)
        IF    ${botonHabilitado} == True
            Click Button    name:add
        #Si no, lo deselecciona
        ELSE
            Click Element    xpath://option[contains(.,${grupo})]
        END

    END
    Log    Done


Agregar Grupos a Seccion
    [Arguments]    ${seccion}
    Open Workbook    ${EXCEL}
    Set active worksheet    Grupos
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook  
    FOR    ${grupo}    IN    @{archivo}
    #Si la seccion del grupo es la misma a la que se le esta agregando
        ${iguales}    Strings Should Be Equal    ${grupo}[Seccion]    ${seccion}
        IF    ${iguales} == True
            Agregar Grupo a Seccion    ${grupo}[Grupo]
            Wait Until Element Is Visible    id:add    1 minute
        END
    END
    Click Button    name:cancel
    Wait Until Page Contains    Agrupamiento    1 min
    Log    Done

Agregar Grupos a Secciones
    Open Workbook    ${EXCEL}
    Set active worksheet    Secciones
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    ${i}=    Set Variable    ${1}
    FOR    ${seccion}    IN    @{archivo}
        ${locator}    Get Position In Table    ${i}
        Click Element    ${locator}
        Wait Until Element Is Visible    name:cancel    1 min
        Agregar Grupos a Seccion    ${seccion}[Seccion]
        ${i}=    Evaluate    ${i} + 1
    END

Interfaz Final
    Add heading    El proceso ha terminado, haga click en close.
    Run dialog    title=Cierre esto    height=350    width=512

*** Tasks ***

#    RECORDAR
#    Su sesión ha excedido el tiempo límite. Por favor, entre de nuevo.
#    //option[contains(text(),'Test')]  El test puede ser una variable
#    Algo de las secciones
#

Minimal task
    Abrir UVirtual
    Seleccionar Curso
    Abrir Menu
    Ir a Participantes
    Ir a Seccion Grupos
    Crear Grupos
    Agregar alumnos
    Ir a Agrupamientos
    Crear Agrupamientos
    Agregar Grupos a Secciones
    Interfaz Final
    Log    Done.