using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using ServiHogarConnect.API.Data;

#nullable disable

namespace ServiHogarConnect.API.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20261002210000_AddServiceCatalog")]
public partial class AddServiceCatalog : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<bool>(
            name: "Activa",
            table: "CategoriasServicio",
            type: "boolean",
            nullable: false,
            defaultValue: true);

        migrationBuilder.Sql(
            """
            INSERT INTO "CategoriasServicio" ("Nombre", "Descripcion")
            SELECT catalogo."Nombre", catalogo."Descripcion"
            FROM (VALUES
                ('Plomería', 'Fugas, tuberías, grifos y sanitarios'),
                ('Electricidad', 'Instalaciones, iluminación y averías'),
                ('Limpieza', 'Limpieza general y profunda'),
                ('Pintura', 'Paredes, interiores y exteriores'),
                ('Cerrajería', 'Cerraduras, puertas y llaves'),
                ('Aire acondicionado', 'Instalación y mantenimiento'),
                ('Jardinería', 'Podado, jardines y mantenimiento'),
                ('Carpintería', 'Muebles, puertas y reparaciones'),
                ('Reparaciones generales', 'Arreglos domésticos diversos'),
                ('Instalaciones', 'Montaje y colocación de equipos')
            ) AS catalogo("Nombre", "Descripcion")
            WHERE NOT EXISTS (
                SELECT 1
                FROM "CategoriasServicio" existente
                WHERE translate(lower(trim(existente."Nombre")), 'áéíóúüñ', 'aeiouun')
                    = translate(lower(trim(catalogo."Nombre")), 'áéíóúüñ', 'aeiouun')
            )
            ON CONFLICT ("Nombre") DO NOTHING;
            """);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "Activa",
            table: "CategoriasServicio");
    }
}
