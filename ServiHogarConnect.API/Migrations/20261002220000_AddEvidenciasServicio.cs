using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ServiHogarConnect.API.Migrations;

[Migration("20261002220000_AddEvidenciasServicio")]
public partial class AddEvidenciasServicio : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "EvidenciasServicio",
            columns: table => new
            {
                IdEvidencia = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy",
                        Npgsql.EntityFrameworkCore.PostgreSQL.Metadata
                            .NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                IdSolicitud = table.Column<int>(type: "integer", nullable: false),
                StorageKey = table.Column<string>(
                    type: "character varying(300)",
                    maxLength: 300,
                    nullable: false),
                NombreArchivo = table.Column<string>(
                    type: "character varying(255)",
                    maxLength: 255,
                    nullable: false),
                TipoContenido = table.Column<string>(
                    type: "character varying(50)",
                    maxLength: 50,
                    nullable: false),
                TamanoBytes = table.Column<long>(type: "bigint", nullable: false),
                FechaCreacion = table.Column<DateTime>(
                    type: "timestamp with time zone",
                    nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_EvidenciasServicio", x => x.IdEvidencia);
                table.ForeignKey(
                    name: "FK_EvidenciasServicio_SolicitudesServicio_IdSolicitud",
                    column: x => x.IdSolicitud,
                    principalTable: "SolicitudesServicio",
                    principalColumn: "IdSolicitud",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_EvidenciasServicio_IdSolicitud",
            table: "EvidenciasServicio",
            column: "IdSolicitud");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "EvidenciasServicio");
    }
}
