<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Psicología a tu alcance - Agendar Cita</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
    <h1>Agendar Cita - Psicología a tu alcance</h1>
    <form action="CitaServlet" method="post">
        <div class="form-group">
            <label for="nombre">Nombre:</label>
            <input type="text" id="nombre" name="nombre" required>
        </div>
        <div class="form-group">
            <label for="email">Email:</label>
            <input type="email" id="email" name="email" required>
        </div>
        <div class="form-group">
            <label for="telefono">Teléfono:</label>
            <input type="text" id="telefono" name="telefono" required>
        </div>
        <div class="form-group">
            <label for="motivo">Motivo de la cita:</label>
            <textarea id="motivo" name="motivo" required></textarea>
        </div>
        <div class="form-group">
            <label for="fechaHora">Fecha y hora:</label>
            <input type="datetime-local" id="fechaHora" name="fechaHora" required>
        </div>
        <div class="form-group">
            <label for="psicologo">Psicólogo:</label>
            <select id="psicologo" name="psicologo" required>
                <option value="">Seleccione...</option>
                <option value="Dra. Ana Pérez">Dra. Ana Pérez</option>
                <option value="Dr. Juan Gómez">Dr. Juan Gómez</option>
                <option value="Lic. Marta Ruiz">Lic. Marta Ruiz</option>
            </select>
        </div>
        <button type="submit">Agendar cita</button>
    </form>
</div>
<div class="unidad-section">
    <%@ include file="unidad1.jsp" %>
</div>
</body>
</html>