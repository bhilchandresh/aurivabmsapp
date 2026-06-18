const fs = require('fs');

const fixSignatureAlign = (file) => {
  let content = fs.readFileSync(file, 'utf8');

  // Replace the return Align(alignment: Alignment.centerRight, child: SizedBox(width: 140
  // with a Row that matches the Subtotal flex layout.
  
  const oldCode = `      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 140,`;

  const newCode = `      return Row(
        children: [
          const Expanded(flex: 55, child: SizedBox.shrink()),
          const SizedBox(width: 24),
          Expanded(
            flex: 40,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 140,`;

  // Need to close the row at the very end of the builder!
  // It looks like:
  /*
              ),
            ],
          ),
        ),
      );
    });
  }
  */

  const oldCodeEnd = `            ],
          ),
        ),
      );
    });
  }`;

  const newCodeEnd = `            ],
          ),
        ),
            ),
          ),
        ],
      );
    });
  }`;

  content = content.replace(oldCode, newCode);
  content = content.replace(oldCodeEnd, newCodeEnd);

  fs.writeFileSync(file, content);
};

fixSignatureAlign('lib/features/invoices/templates/minimalist_template.dart');
fixSignatureAlign('lib/features/quotations/templates/minimalist_template.dart');
