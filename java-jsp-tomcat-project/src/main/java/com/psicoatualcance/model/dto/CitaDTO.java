package com.psicoatualcance.model.dto;

import java.time.LocalDateTime;

public class CitaDTO {
    private int id;
    private int usuarioId;
    private String motivo;
    private LocalDateTime fechaHora;
    private String psicologo;

    public CitaDTO() {}

    public CitaDTO(int id, int usuarioId, String motivo, LocalDateTime fechaHora, String psicologo) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.motivo = motivo;
        this.fechaHora = fechaHora;
        this.psicologo = psicologo;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getUsuarioId() { return usuarioId; }
    public void setUsuarioId(int usuarioId) { this.usuarioId = usuarioId; }

    public String getMotivo() { return motivo; }
    public void setMotivo(String motivo) { this.motivo = motivo; }

    public LocalDateTime getFechaHora() { return fechaHora; }
    public void setFechaHora(LocalDateTime fechaHora) { this.fechaHora = fechaHora; }

    public String getPsicologo() { return psicologo; }
    public void setPsicologo(String psicologo) { this.psicologo = psicologo; }
}
