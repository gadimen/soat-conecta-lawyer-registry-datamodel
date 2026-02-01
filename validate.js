const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const fs = require('fs');
const path = require('path');

// Initialize AJV with JSON Schema draft-07
const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

// Load all schemas
const schemasDir = path.join(__dirname, 'schemas');
const schemas = {};

function loadSchema(filename) {
  const filePath = path.join(schemasDir, filename);
  const schema = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  schemas[filename] = schema;
  return schema;
}

// Load all schemas
const schemaFiles = [
  'address.schema.json',
  'certification.schema.json',
  'specialization.schema.json',
  'lawfirm.schema.json',
  'lawyer.schema.json'
];

schemaFiles.forEach(file => {
  const schema = loadSchema(file);
  ajv.addSchema(schema);
});

// Validate example files
function validateExample(schemaFile, exampleFile) {
  const examplePath = path.join(__dirname, 'examples', exampleFile);
  const example = JSON.parse(fs.readFileSync(examplePath, 'utf8'));
  
  const schema = schemas[schemaFile];
  const validate = ajv.getSchema(schema.$id);
  
  const valid = validate(example);
  
  console.log(`\nValidating ${exampleFile} against ${schemaFile}:`);
  if (valid) {
    console.log('✓ Valid');
  } else {
    console.log('✗ Invalid');
    console.log('Errors:');
    validate.errors.forEach(err => {
      console.log(`  - ${err.instancePath}: ${err.message}`);
    });
  }
  
  return valid;
}

// Run validation
console.log('='.repeat(60));
console.log('SOAT Conecta Lawyer Registry Data Model Validation');
console.log('='.repeat(60));

let allValid = true;

allValid = validateExample('lawyer.schema.json', 'lawyer-example.json') && allValid;
allValid = validateExample('lawfirm.schema.json', 'lawfirm-example.json') && allValid;

console.log('\n' + '='.repeat(60));
if (allValid) {
  console.log('✓ All validations passed!');
  process.exit(0);
} else {
  console.log('✗ Some validations failed!');
  process.exit(1);
}
