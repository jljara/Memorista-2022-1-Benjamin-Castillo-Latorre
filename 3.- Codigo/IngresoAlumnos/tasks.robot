*** Settings ***
Documentation     Robot que descarga logs
...               en la plataforma UVirtual
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Dialogs
Library    Collections
Library    util.py
Library    RPA.Desktop
Library    RPA.Excel.Files
*** Variables ***
${USUARIO}    %{USUARIO_PROFESOR}
${PASSWORD}   %{PASSWORD}
${ASIGNATURA}    %{ASIGNATURA}
${EXCEL}    %{ENTRADA}

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

Ir a Zona de Inscripcion
    Click Button    xpath://input[@value='Matricular usuarios']
    Wait Until Page Contains    Usuarios matriculados    1 min

Inscribir Alumno
    [Arguments]    ${nombreAlumno}    ${correoAlumno}
    ${matriculado}    Evaluate    False

    #Se verifica si el alumno ya esta inscrito para asi no inscribirlo
    ${nombrePreEncontrado}    Does Page Contain Element    //option[contains(.,'${nombreAlumno}')]
    ${correoPreEncontrado}    Does Page Contain Element   //option[contains(.,'${correoAlumno}')]
    IF    ${nombrePreEncontrado} == True or ${correoPreEncontrado} == True
        ${matriculado}    Evaluate    True
    #Si no esta inscrito
    ELSE
        Input Text    id:addselect_searchtext    ${nombreAlumno}
        TRY
            Wait Until Page Contains Element   xpath://option[contains(.,'${correoAlumno}')]    5 seconds    error
        EXCEPT  error
            Log    error
        END
        ${nombreEncontrado}    Does Page Contain Element    xpath://option[contains(.,'${nombreAlumno}')]
        ${correoEncontrado}    Does Page Contain Element    xpath://option[contains(.,'${correoAlumno}')]
        
        IF    ${correoEncontrado} == True
            Click Element    xpath://option[contains(.,'${correoAlumno}')]
            Click Button    id:add
            ${matriculado}    Evaluate    True
        ELSE IF    ${nombreEncontrado} == True
            Click Element    xpath://option[contains(.,'${nombreAlumno}')]
            Click Button    id:add
            ${matriculado}    Evaluate    True
        ELSE
            ${matriculado}    Evaluate    False
        END
        Click Button    id:addselect_clearbutton
        Log    Done
    END    
    [Return]    ${matriculado}
#	https://uvirtual.usach.cl/moodle/theme/image.php/eguru/core/1645638863/i/loading
Inscribir Alumnos
    Open Workbook    ${EXCEL}
    #Selecciona la hoja de alumnos
    Set Active Worksheet    Alumnos
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    FOR    ${alumno}    IN    @{archivo}
        ${nombreAlumno}    Concat Names    ${alumno}[Nombres]    ${alumno}[Paterno]    ${alumno}[Materno]
        ${matriculado}    Inscribir Alumno    ${nombreAlumno}    ${alumno}[Correo]
    END

Interfaz Final
    Add heading    El proceso ha terminado, haga click en close para terminar.
    Run dialog    title=Cierre esto    height=350    width=512
*** Tasks ***
Minimal task
    Abrir UVirtual
    Seleccionar Curso
    Abrir Menu
    Ir a Participantes    
    Ir a Zona de Inscripcion
    Inscribir Alumnos
    Interfaz Final
    Log    Done.
