package com.psicoatualcance.servlet;

import com.psicoatualcance.model.dto.CitaDTO;
import com.psicoatualcance.model.dto.UsuarioDTO;
import com.psicoatualcance.repository.CitaRepositoryFile;
import com.psicoatualcance.repository.CitaRepositoryMySQL;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.Properties;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.time.LocalDateTime;

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
        // Persist the cita: prefer MySQL if db.properties is provided, otherwise fallback to file
        Properties dbProps = new Properties();
        try (InputStream is = getClass().getClassLoader().getResourceAsStream("db.properties")) {
            if (is != null) dbProps.load(is);
        } catch (IOException ignored) {
        }

        String dbUrl = dbProps.getProperty("db.url", "").trim();
        if (!dbUrl.isEmpty()) {
            // Try saving to MySQL
            String dbUser = dbProps.getProperty("db.user", "");
            String dbPassword = dbProps.getProperty("db.password", "");
            try {
                CitaRepositoryMySQL repo = new CitaRepositoryMySQL(dbUrl, dbUser, dbPassword);
                repo.save(usuario, cita);
            } catch (SQLException ex) {
                ex.printStackTrace();
                // fallback to file if DB save fails
                try {
                    String relative = "/WEB-INF/data/citas.txt";
                    File dataFile = new File(getServletContext().getRealPath(relative));
                    CitaRepositoryFile fileRepo = new CitaRepositoryFile(dataFile);
                    fileRepo.save(usuario, cita);
                } catch (IOException io) {
                    io.printStackTrace();
                }
            }
        } else {
            // Use file repository
            try {
                String relative = "/WEB-INF/data/citas.txt";
                File dataFile = new File(getServletContext().getRealPath(relative));
                CitaRepositoryFile repo = new CitaRepositoryFile(dataFile);
                repo.save(usuario, cita);
            } catch (IOException e) {
                // Log and continue — we'll still show confirmation
                e.printStackTrace();
            }
        }

        request.setAttribute("usuario", usuario);
        request.setAttribute("cita", cita);
        // use absolute path to ensure RequestDispatcher is resolved correctly from root of webapp
        request.getRequestDispatcher("/result.jsp").forward(request, response);
    }
}
