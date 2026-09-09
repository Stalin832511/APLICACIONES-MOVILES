using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ServiHogarConnect.API.Migrations
{
    /// <inheritdoc />
    public partial class AddClientOperationId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ClientOperationId",
                table: "SolicitudesServicio",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_SolicitudesServicio_ClientOperationId",
                table: "SolicitudesServicio",
                column: "ClientOperationId",
                unique: true,
                filter: "\"ClientOperationId\" IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SolicitudesServicio_ClientOperationId",
                table: "SolicitudesServicio");

            migrationBuilder.DropColumn(
                name: "ClientOperationId",
                table: "SolicitudesServicio");
        }
    }
}
