#!/usr/bin/env node

/**
 * ###############################################################################
 * Script Name : aquatic-platform-mm-net-surcharges.js
 * Description : Parses CSV files in a directory to compute surcharge statistics.
 *
 * Author      : Varun Chawla
 * Created On  : March 21, 2026
 * Last Updated: March 21, 2026
 * Version     : 1.0
 * Usage       : cd "/path/to/folder"; chmod +x aquatic-platform-mm-net-surcharges.js; ./aquatic net-surcharges [optional/path/to/csv/folder]
 * Requirements: node
 * ###############################################################################
 */

const fs = require('fs');
const path = require('path');

const targetDir = process.argv[2] || '.';

function parseCSVRow(row) {
    const result = [];
    let curVal = '';
    let inQuotes = false;
    for (let i = 0; i < row.length; i++) {
        if (row[i] === '"') inQuotes = !inQuotes;
        else if (row[i] === ',' && !inQuotes) {
            result.push(curVal.trim());
            curVal = '';
        } else curVal += row[i];
    }
    result.push(curVal.trim());
    return result;
}

function processSurcharges(directoryPath) {
    if (!fs.existsSync(directoryPath)) {
        console.error(`[ERROR] Directory not found: ${directoryPath}`);
        process.exit(1);
    }

    const files = fs.readdirSync(directoryPath).filter(file => file.endsWith('.csv'));

    if (files.length === 0) {
        console.log(`No CSV files found in the directory: ${directoryPath}`);
        return;
    }

    const brandStats = {};

    for (const file of files) {
        const filePath = path.join(directoryPath, file);
        const content = fs.readFileSync(filePath, 'utf-8');

        const lines = content.split(/\r?\n/).filter(line => line.trim() !== '');
        if (lines.length < 2) continue;

        const headers = parseCSVRow(lines[0]);
        const brandIdx = headers.findIndex(h => h === 'Payment Method');
        const surchargeIdx = headers.findIndex(h => h === 'Surcharge Amount');
        const activityIdx = headers.findIndex(h => h === 'Activity');
        const amountIdx = headers.findIndex(h => h === 'Original Amount'); 

        if (brandIdx === -1 || surchargeIdx === -1 || activityIdx === -1 || amountIdx === -1) {
            console.log(`Skipping ${file}: Missing one or more required headers.`);
            continue;
        }

        for (let i = 1; i < lines.length; i++) {
            const columns = parseCSVRow(lines[i]);
            if (columns.length <= Math.max(brandIdx, surchargeIdx, activityIdx, amountIdx)) continue;

            const brand = columns[brandIdx] || 'Unknown';
            const activity = (columns[activityIdx] || '').trim().toLowerCase();

            const surchargeStr = columns[surchargeIdx] || '0';
            const surcharge = parseFloat(surchargeStr.replace(/[$]/g, '').replace(/,/g, '')) || 0;

            const amountStr = columns[amountIdx] || '0';
            const txAmount = parseFloat(amountStr.replace(/[$]/g, '').replace(/,/g, '')) || 0;

            if (!brandStats[brand]) {
                brandStats[brand] = {
                    salesCount: 0, salesAmt: 0,
                    refundsCount: 0, refundsAmt: 0,
                    netSurcharge: 0
                };
            }

            brandStats[brand].netSurcharge += surcharge;

            if (activity === 'payment') {
                brandStats[brand].salesCount += 1;
                brandStats[brand].salesAmt += txAmount;
            } else if (activity === 'refund') {
                brandStats[brand].refundsCount += 1;
                brandStats[brand].refundsAmt += Math.abs(txAmount);
            }
        }
    }

    let tableDataRaw = [];
    let totals = {
        salesCount: 0, salesAmt: 0,
        refundsCount: 0, refundsAmt: 0,
        netNumber: 0, netSales: 0, netSurcharge: 0
    };

    for (const [brand, stats] of Object.entries(brandStats)) {
        const netNumber = stats.salesCount - stats.refundsCount;
        const netSales = stats.salesAmt - stats.refundsAmt;

        tableDataRaw.push({
            brand: brand,
            sales: stats.salesCount,
            salesAmt: stats.salesAmt,
            refunds: stats.refundsCount,
            refundsAmt: stats.refundsAmt,
            netNumber: netNumber,
            netSales: netSales,
            netSurcharge: stats.netSurcharge
        });

        totals.salesCount += stats.salesCount;
        totals.salesAmt += stats.salesAmt;
        totals.refundsCount += stats.refundsCount;
        totals.refundsAmt += stats.refundsAmt;
        totals.netNumber += netNumber;
        totals.netSales += netSales;
        totals.netSurcharge += stats.netSurcharge;
    }

    tableDataRaw.sort((a, b) => b.sales - a.sales);

    const currencyFormatter = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
    });

    const finalTable = tableDataRaw.map(row => ({
        'Name': row.brand,
        'Sales': row.sales,
        'Sales ($)': currencyFormatter.format(row.salesAmt),
        'Refunds': row.refunds,
        'Refunds($)': currencyFormatter.format(row.refundsAmt),
        'Net Number': row.netNumber,
        'Net Sales($)': currencyFormatter.format(row.netSales),
        'Average Ticket ($)': row.sales > 0 ? currencyFormatter.format(row.salesAmt / row.sales) : currencyFormatter.format(0),
        'Net Surcharges ($)': currencyFormatter.format(row.netSurcharge)
    }));

    finalTable.push({
        'Name': '',
        'Sales': totals.salesCount,
        'Sales ($)': currencyFormatter.format(totals.salesAmt),
        'Refunds': totals.refundsCount,
        'Refunds($)': currencyFormatter.format(totals.refundsAmt),
        'Net Number': totals.netNumber,
        'Net Sales($)': currencyFormatter.format(totals.netSales),
        'Average Ticket ($)': totals.salesCount > 0 ? currencyFormatter.format(totals.salesAmt / totals.salesCount) : currencyFormatter.format(0),
        'Net Surcharges ($)': currencyFormatter.format(totals.netSurcharge)
    });

    console.log(`\n[INFO] Processed ${files.length} CSV files.\n`);
    console.table(finalTable);
}

processSurcharges(targetDir);
