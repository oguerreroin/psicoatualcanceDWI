package com.psicoatualcance.servlet;

import com.psicoatualcance.model.dto.CitaDTO;
import com.psicoatualcance.model.dto.UsuarioDTO;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@WebServlet(name = "CitaServlet", urlPatterns = {"/CitaServlet"})
public class CitaServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String nombre = request.getParameter("nombre");
        String email = request.getParameter("email");
        String telefono = request.getParameter("telefono");
        String motivo = request.getParameter("motivo");
        String fechaHoraStr = request.getParameter("fechaHora");
        String psicologo = request.getParameter("psicologo");

        UsuarioDTO usuario = new UsuarioDTO(0, nombre, email, telefono);
        LocalDateTime fechaHora = LocalDateTime.parse(fechaHoraStr);
        CitaDTO cita = new CitaDTO(0, 0, motivo, fechaHora, psicologo);

        request.setAttribute("usuario", usuario);
        request.setAttribute("cita", cita);
        request.getRequestDispatcher("result.jsp").forward(request, response);
    }
}
