<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.psicoatualcance.model.dto.CitaDTO,com.psicoatualcance.model.dto.UsuarioDTO" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Cita Agendada - Psicología a tu alcance</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <h1>Cita Agendada</h1>
    <p>¡Gracias por agendar tu cita en <strong>Psicología a tu alcance</strong>!</p>
    <h2>Resumen de la cita:</h2>
    <ul>
        <li><strong>Nombre:</strong> ${usuario.nombre}</li>
        <li><strong>Email:</strong> ${usuario.email}</li>
        <li><strong>Teléfono:</strong> ${usuario.telefono}</li>
        <li><strong>Motivo:</strong> ${cita.motivo}</li>
        <li><strong>Fecha y hora:</strong> ${cita.fechaHora}</li>
        <li><strong>Psicólogo:</strong> ${cita.psicologo}</li>
    </ul>
    <a href="index.jsp"><button>Agendar otra cita</button></a>
    <a href="DownloadCitas"><button>Ver/Descargar todas las citas</button></a>
</div>
<div class="unidad-section">
    <%@ include file="unidad1.jsp" %>
</div>
</body>
</html>
