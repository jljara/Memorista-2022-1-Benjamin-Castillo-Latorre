*** Settings ***
Documentation     Robot que recolecta las notas
...               en la plataforma UVirtual
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Dialogs
Library    RPA.Tables
Library    tables.py
Library    util.py
Library    RPA.Excel.Files
Library    Collections

*** Variables ***
${USUARIO}    %{USUARIO_PROFESOR}
${PASSWORD}   %{PASSWORD}
${ASIGNATURA}    %{ASIGNATURA}
#Agrupamiento/devdata/Grupos.xlsx
${EVALUACION}    %{EVALUACION}
${EXCEL}    %{ENTRADA}
${SALIDA_EXCEL}    %{SALIDA}

*** Keywords ***

#Este proceso no ingresa el captcha si no que le pide al usuario ingresarlo
#una vez se cierra sigue el proceso
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

#Ingresa a la seccion de notas
Ver Notas
    Log    Notas.
    Abrir Menu
    Click Link    link:Calificaciones
    Wait Until Page Contains    Informe del calificador    1 min

#Ingresa a la evaluacion
Ingresar A Evaluacion
    Interfaz Seleccionar Evaluacion
    Wait Until Element Is Visible    id:id_pagesize    1 min


#Establece filtros para leer completamente la tabla
#Salida: el numero de intentos realizados
Filtrar Evaluacion
    #Se obtienen la cantidad de alumnos que han rendido la evaluacion y se ingresa en
    #la cantidad de alumnos a mostrar
    ${intentos}    Get Element Attribute    css:.quizattemptcounts:nth-child(3)    innerHTML
    ${intentos}    Get Intentos    ${intentos}
    Input Text    id:id_pagesize    ${intentos}
    #Solo se muestran los alumnos matriculados, ya que asi tambien se ve quienes no lo han dado
    Select From List By Value    id:id_attempts    enrolled_with
    Select From List By Value    id:id_slotmarks    0
    #Se hace click y se espera a que cargue la tabla
    Click Button    id:id_submitbutton
    Wait Until Element Is Visible    //table[@id='attempts']
    [Return]    ${intentos}

Interfaz Seleccionar Evaluacion
    Add heading    No se encontro la evaluacion por favor seleccione una, espere a que cargue y luego haga click en close
    Run dialog    title=Seleccione evaluacion   height=350    width=512

Obtener Tipo De Evaluacion
    ${tipoEvaluacion}    Set Variable    Quiz
    ${textoSumario}    Does Page Contain    Sumario de calificaciones
    IF    ${textoSumario} == True
        ${tipoEvaluacion}    Set Variable    Entrega
    END
    [Return]    ${tipoEvaluacion}

#Obtiene una tabla html dado su id y la retorna
#Salida: una variable que contiene la tabla html
Get HTML table
    ${html_table}=    Get Element Attribute    css:table#attempts    outerHTML
    [Return]    ${html_table}

#Transforma la tabla html en una tabla con las variables de nombre correo y nota
#Salida: una tabla
Read HTML table as Table
    #Leer la tabla html
    ${html_table}=    Get HTML table
    #Transformar la tabla html a una tabla
    ${table}=    Read Table From Html    ${html_table}
    #Remplaza el nombre default de la tabla para poder eliminar las necesarias
    ${nombreColumnas}    Create List    null1    null2    Nombre    Correo    Estado    Inicio    Fin    Tiempo    Nota
    Rename Table Columns    ${table}    ${nombreColumnas}
    Pop Table Column    ${table}    null1
    Pop Table Column    ${table}    null2
    Pop Table Column    ${table}    Estado
    Pop Table Column    ${table}    Inicio
    Pop Table Column    ${table}    Fin
    Pop Table Column    ${table}    Tiempo
    [Return]    ${table}

#Compara la tabla del archivo excel con la obtenida por el html
#Entrada: una tabla html transformada a tabla
Comparar Alumnos Tabla Quiz HTML
    [Arguments]    ${tabla}
    Open Workbook    ${EXCEL}
    #Selecciona la hoja de alumnos
    Set Active Worksheet    Alumnos
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    #Crea las columnas para el earchivo de salida
    ${nombreColumnas}    Create List    Nombre    Correo    Nota
    #Tabla que almacena los alumnos, se guardara en un archivo excel 
    ${tablaSalida}    Create Table    columns=${nombreColumnas}
    #Se verifica que la escala es correcta
    ${escalaIncorrecta}    Does Page Contain    Calificación/6,00
    #Para cada alumno (fila) en el archivo
    FOR    ${alumno}    IN    @{archivo}
        #Obtiene una tabla en donde las filas en donde el correo del html sea igual al de la tabla del excel
        ${aux}    Find Table Rows    ${tabla}    Correo    contains    ${alumno}[Correo]
        #obtiene la cantidad de filas de la tabla anterior
        ${rows}  ${columns}=    Get table dimensions    ${aux}
        #Si solo hay una fila
        IF    ${rows} == 1
            #Se cambia el nombre (viene con Revision del intento despues del nombre)
            ${nombre}    RPA.Tables.Get Table Cell    ${aux}    0    0
            ${nombre}    Format Table Name    ${nombre}
            #Se cambia la nota si esta con la escala mala
            ${nota}    RPA.Tables.Get Table Cell    ${aux}    0    2
            ${nota}    String To Float    ${nota}    ${escalaIncorrecta}        
            Set Table Cell    ${aux}    0    0    ${nombre}
            Set Table Cell    ${aux}    0    2    ${nota}
            #Se agrega la fila a la tabla de salida
            ${filaAgregar}    Get Table Row    ${aux}    0
            Add Table Row    ${tablaSalida}    ${filaAgregar}
        END
    END
    #Se exporta la tabla como archivo csv
     Write table to CSV    ${tablaSalida}    Notas.csv
    
#TODO
#crear interfaz q se muestre si no encuentra la evaluacion
#Si la pagina contiene Calificacion/6,00 o un 0,00 la nota esta bajo
#Comparar velocidades


Obtener Notas
    [Arguments]    ${tipoEvaluacion}
    ${esQuiz}    Strings Should Be Equal    Quiz    ${tipoEvaluacion}
    IF    ${esQuiz} == True
        ${intentos}    Filtrar Evaluacion
        ${test}    Read HTML table as Table
        Comparar Alumnos Tabla Quiz HTML    ${test}
    ELSE
        Click Button    xpath:(//a[contains(text(),'Ver todos los envíos')])[2]
        Wait Until Page Contains Element    xpath://label[contains(.,'Acción sobre las calificaciones')]
    END
    
Interfaz Final
    Add heading    El proceso ha terminado, cierre esto. El archivo CSV con las notas esta en la carpeta de este robot y se llama Notas.csv
    Run dialog    title=Cierre esto    height=350    width=512
*** Tasks ***
Minimal task    
    Abrir UVirtual
    Seleccionar Curso
    Ver Notas
    Ingresar A Evaluacion
    ${tipoEvaluacion}    Obtener Tipo De Evaluacion
    Obtener Notas    ${tipoEvaluacion}
    Interfaz Final
    Log    Done.
