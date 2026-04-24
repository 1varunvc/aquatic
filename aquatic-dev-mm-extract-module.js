// ###############################################################################
// Script Name : mm-extract-module
// Description : Extracts TSV formatted test ownership data from HTML tables.
// Author      : Varun Chawla
// Created On  : March 21, 2026
// Last Updated: March 21, 2026
// Version     : 1.0
// Usage       : ./aquatic snippet mm-extract-module [suiteHeader] [classRow] [classLink] [methodRow] [methodLink] [ownershipElem] [teamName]
// ###############################################################################

// Create output array
const tableRows = [];

// 1. Target suite headers
const suiteHeaders = document.querySelectorAll('___SUITE_HEADER___');

suiteHeaders.forEach(header => {
    const parentContainer = header.closest('td');

    if (parentContainer) {
        // 2. Locate all class rows
        const classRows = parentContainer.querySelectorAll('___CLASS_ROW___');
        
        classRows.forEach(row => {
            const classLink = row.querySelector('___CLASS_LINK___');
            if (!classLink) return;

            // Just the short class name
            const testClassName = classLink.textContent.trim();

            // 3. Find the container rows for each method
            const methodContainers = row.querySelectorAll('___METHOD_ROW___');
            
            let isFirstMethod = true;

            methodContainers.forEach(methodRow => {
                // Extract Method Name
                const methodLink = methodRow.querySelector('___METHOD_LINK___');
                const testMethodName = methodLink ? methodLink.textContent.trim() : "Unknown Method";
                
                // Extract Ownership/Author and remove team name
                const ownershipElem = methodRow.querySelector('___OWNERSHIP_ELEM___');
                let ownership = "";
                if (ownershipElem) {
                    // Grab text, remove team name (case-insensitive just in case), and clean up spaces
                    ownership = ownershipElem.textContent
                        .replace(/___TEAM_NAME___/gi, '')  // Removes the team name
                        .replace(/\s+/g, ' ')    // Cleans up the extra icon spaces
                        .trim();                 // Removes leading/trailing spaces
                }

                // 4. Push to array with TSV formatting
                if (isFirstMethod) {
                    tableRows.push(`${testClassName}\t${testMethodName}\t${ownership}`);
                    isFirstMethod = false;
                } else {
                    tableRows.push(`\t${testMethodName}\t${ownership}`);
                }
            });
        });
    }
});

// 5. Output the result formatted cleanly
console.log("---- COPY EVERYTHING BELOW THIS LINE ----");
console.log(tableRows.join('\n'));
console.log("---- COPY EVERYTHING ABOVE THIS LINE ----");
