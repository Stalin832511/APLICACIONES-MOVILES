using Microsoft.EntityFrameworkCore;
using ServiHogarConnect.API.Models;

namespace ServiHogarConnect.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Usuario> Usuarios => Set<Usuario>();

    public DbSet<Profesional> Profesionales => Set<Profesional>();

    public DbSet<CategoriaServicio> CategoriasServicio => Set<CategoriaServicio>();

    public DbSet<SolicitudServicio> SolicitudesServicio => Set<SolicitudServicio>();

    public DbSet<Cotizacion> Cotizaciones => Set<Cotizacion>();

    public DbSet<Calificacion> Calificaciones => Set<Calificacion>();

    public DbSet<MensajeChat> MensajesChat => Set<MensajeChat>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ================================
        // USUARIO
        // ================================

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.HasKey(u => u.IdUsuario);

            entity.Property(u => u.Nombre)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(u => u.Apellido)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(u => u.Email)
                .HasMaxLength(150)
                .IsRequired();

            entity.HasIndex(u => u.Email)
                .IsUnique();

            entity.Property(u => u.PasswordHash)
                .HasMaxLength(255)
                .IsRequired();

            entity.Property(u => u.TipoUsuario)
                .HasMaxLength(20)
                .IsRequired();
        });

        // ================================
        // PROFESIONAL
        // ================================

        modelBuilder.Entity<Profesional>(entity =>
        {
            entity.HasKey(p => p.IdProfesional);

            entity.HasOne(p => p.Usuario)
                .WithOne(u => u.Profesional)
                .HasForeignKey<Profesional>(p => p.IdUsuario)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(p => p.IdUsuario)
                .IsUnique();

            entity.Property(p => p.Especialidad)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(p => p.TarifaHora)
                .HasPrecision(10, 2);

            entity.Property(p => p.CalificacionPromedio)
                .HasPrecision(3, 2);
        });

        // ================================
        // CATEGORÍA
        // ================================

        modelBuilder.Entity<CategoriaServicio>(entity =>
        {
            entity.HasKey(c => c.IdCategoria);

            entity.Property(c => c.Nombre)
                .HasMaxLength(100)
                .IsRequired();

            entity.HasIndex(c => c.Nombre)
                .IsUnique();
        });

        // ================================
        // SOLICITUD DE SERVICIO
        // ================================

        modelBuilder.Entity<SolicitudServicio>(entity =>
        {
            entity.HasKey(s => s.IdSolicitud);

            entity.HasOne(s => s.Usuario)
                .WithMany(u => u.Solicitudes)
                .HasForeignKey(s => s.IdUsuario)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(s => s.Categoria)
                .WithMany(c => c.Solicitudes)
                .HasForeignKey(s => s.IdCategoria)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(s => s.Descripcion)
                .IsRequired();

            entity.Property(s => s.Estado)
                .HasMaxLength(20)
                .IsRequired();

            entity.Property(s => s.Latitud)
                .HasPrecision(10, 8);

            entity.Property(s => s.Longitud)
                .HasPrecision(11, 8);

            entity.HasIndex(s => s.Estado);

            entity.HasIndex(s => s.FechaCreacion);
        });

        // ================================
        // COTIZACIÓN
        // ================================

        modelBuilder.Entity<Cotizacion>(entity =>
        {
            entity.HasKey(c => c.IdCotizacion);

            entity.HasOne(c => c.Solicitud)
                .WithMany(s => s.Cotizaciones)
                .HasForeignKey(c => c.IdSolicitud)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(c => c.Profesional)
                .WithMany(p => p.Cotizaciones)
                .HasForeignKey(c => c.IdProfesional)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(c => c.PrecioOfertado)
                .HasPrecision(10, 2);

            entity.HasIndex(c => c.IdSolicitud);
        });

        // ================================
        // CALIFICACIÓN
        // ================================

        modelBuilder.Entity<Calificacion>(entity =>
        {
            entity.HasKey(c => c.IdCalificacion);

            entity.HasOne(c => c.Usuario)
                .WithMany(u => u.Calificaciones)
                .HasForeignKey(c => c.IdUsuario)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(c => c.Profesional)
                .WithMany(p => p.Calificaciones)
                .HasForeignKey(c => c.IdProfesional)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(c => c.Puntuacion)
                .IsRequired();

            entity.HasIndex(c => new
            {
                c.IdUsuario,
                c.IdProfesional
            })
            .IsUnique();
        });

        // ================================
        // MENSAJES
        // ================================

        modelBuilder.Entity<MensajeChat>(entity =>
        {
            entity.HasKey(m => m.IdMensaje);

            entity.HasOne(m => m.Emisor)
                .WithMany(u => u.MensajesEnviados)
                .HasForeignKey(m => m.IdEmisor)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(m => m.Receptor)
                .WithMany(u => u.MensajesRecibidos)
                .HasForeignKey(m => m.IdReceptor)
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(m => m.Mensaje)
                .IsRequired();

            entity.HasIndex(m => new
            {
                m.IdEmisor,
                m.IdReceptor,
                m.FechaEnvio
            });
        });
    }
}