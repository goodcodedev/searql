//const sql = require('mssql')
//const csv = require('csv-parse')
import fs, { readFileSync } from "node:fs";
import { parse } from "csv-parse";
import sql from "mssql";
import { fileURLToPath } from 'url';
import { dirname } from 'path';


const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);


let numIndexed = 0;

async function insertWords(words, fieldId, entityId) {
    const statement = readFileSync(__dirname + '/insertWords.sql', {
        encoding: "utf-8"
    });
    let start = new Date();
    await query(statement, {
        words: sql.VarChar(),
        entityId: sql.Int(),
        fieldId: sql.Int()
    }, {
        words: words,
        entityId: entityId,
        fieldId: fieldId
    });
    numIndexed++;
    console.log(`Indexed ${numIndexed} in ${new Date() - start}`);
}

async function insertEntity(Uri, Label, Description) {
    const check = await query(`select * from LabelEntity where Uri=@Uri`, {Uri: sql.VarChar()}, {Uri: Uri});
    if (check.length > 0) {
        return check[0].Id;
    }
    await query(`
        INSERT INTO LabelEntity (Label, Description, Uri) VALUES (
            @Label,
            @Description,
            @Uri
        )
    `, {
        Label: sql.VarChar(),
        Description: sql.VarChar(),
        Uri: sql.VarChar()
    }, {
        Label: Label,
        Description: Description,
        Uri: Uri
    });
    const inserted = await query(`select * from LabelEntity where Uri=@Uri`, {Uri: sql.VarChar()}, {Uri: Uri});
    return inserted[0].Id;
}


async function indexCsv(csvName) {
    const parser = parse({
        delimiter: ",",

    });

    let records = [];

    // Use the readable stream api to consume records
    parser.on("readable", async function () {
        let record;
        let isFirst = true;
        while ((record = parser.read()) !== null) {
            if (isFirst) {
                isFirst = false;
                continue;
            }
            try {
                let entityId = await insertEntity(record[1], record[4], record[12]);
                // Label
                await insertWords(record[4], 1, entityId);
                // Description
                await insertWords(record[12], 2, entityId);
                records.push(record);
            } catch (err) {
                console.error(err);
            }
        }
    });
    // Catch any error
    parser.on("error", function (err) {
        console.error(err.message);
    });
    parser.on("close", function(err) {
        console.log("Close");
    });

    fs.createReadStream(__dirname + `/../csv/${csvName}.csv`).pipe(parser);
}

async function query(statement, types, values) {
    const p = new sql.PreparedStatement();
    if (types) {
        for (let name in types) {
            p.input(name, types[name]);
        }
    }
    return new Promise((resolve, reject) => {
        p.prepare(statement, (err) => {
            if (err) {
                reject(err);
                return;
            }
            p.execute(values || {}, (err, result) => {
                if (err) {
                    reject(err);
                    return;
                }
                p.unprepare(err => {
                    if (err) {
                        reject(err);
                        return;
                    }
                    resolve(result);
                });
            });
        });
    });
}
node
//https://stackoverflow.com/questions/64939616/connect-to-sql-server-running-on-windows-host-from-a-wsl-2-ubuntu-sqlcmd
// ip route show | grep -i default | awk '{ print $3}'

(async () => {
    try {
        // make sure that any items are correctly URL encoded in the connection string
        let conn = await sql.connect({
            user: 'sa',
            password: 'pass',
            server: "xxx", // You can use 'localhost\\instance' to connect to named instance
            database: 'SearchTest',
        });

        //await indexCsv("researchSkillsCollection_no");
        await indexCsv("skills_no");


    } catch (err) {
        console.log(err)
        // ... error checks
    }
})()