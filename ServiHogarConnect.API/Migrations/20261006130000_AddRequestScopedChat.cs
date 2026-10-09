using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using ServiHogarConnect.API.Data;

#nullable disable

namespace ServiHogarConnect.API.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20261006130000_AddRequestScopedChat")]
public partial class AddRequestScopedChat : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<int>(
            name: "IdSolicitud",
            table: "MensajesChat",
            type: "integer",
            nullable: true);

        migrationBuilder.CreateIndex(
            name: "IX_MensajesChat_IdSolicitud",
            table: "MensajesChat",
            column: "IdSolicitud");

        migrationBuilder.AddForeignKey(
            name: "FK_MensajesChat_SolicitudesServicio_IdSolicitud",
            table: "MensajesChat",
            column: "IdSolicitud",
            principalTable: "SolicitudesServicio",
            principalColumn: "IdSolicitud",
            onDelete: ReferentialAction.Cascade);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey(
            name: "FK_MensajesChat_SolicitudesServicio_IdSolicitud",
            table: "MensajesChat");

        migrationBuilder.DropIndex(
            name: "IX_MensajesChat_IdSolicitud",
            table: "MensajesChat");

        migrationBuilder.DropColumn(
            name: "IdSolicitud",
            table: "MensajesChat");
    }
}
