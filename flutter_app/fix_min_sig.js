const fs = require('fs');

const fixSignature = (file) => {
  let content = fs.readFileSync(file, 'utf8');

  const oldSig = `  Widget _buildSignatorySection() {
    return GetBuilder<AuthController>(builder: (authController) {
      final String? authSignature = authController.userProfile.value?.signatureImage;
      final String displayName = authController.userProfile.value?.name ?? params.tenant['name'] ?? '';

      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 140,
          child: Column(
            children: [
              if (authSignature != null && authSignature.isNotEmpty)
                _buildLogoWidget(authSignature, height: 40, width: 140, fit: BoxFit.contain)
              else
                Container(
                  height: 40,
                  width: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  alignment: Alignment.center,
                  child: Text('Sign Here', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
                ),
              const SizedBox(height: 4),
              Text(
                displayName.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'AUTHORIZED SIGNATORY',
                style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }`;

  const newSig = `  Widget _buildSignatorySection() {
    return GetBuilder<AuthController>(builder: (authController) {
      final String authSignature = authController.userSignature.value;
      final String displayName = authController.userName.value.isNotEmpty ? authController.userName.value : (params.tenant['name'] ?? '');

      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 140,
          child: Column(
            children: [
              if (authSignature.isNotEmpty)
                _buildLogoWidget(authSignature, height: 40, width: 140, fit: BoxFit.contain)
              else if (params.tenant['signatureImage'] != null && params.tenant['signatureImage'].isNotEmpty)
                _buildLogoWidget(params.tenant['signatureImage'], height: 40, width: 140, fit: BoxFit.contain)
              else
                Container(
                  height: 40,
                  width: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  alignment: Alignment.center,
                  child: Text('Sign Here', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
                ),
              const SizedBox(height: 4),
              Text(
                displayName.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'AUTHORIZED SIGNATORY',
                style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }`;

  content = content.replace(oldSig, newSig);

  // Fallback if formatting was slightly off
  if (content.indexOf("userProfile.value?.signatureImage") !== -1) {
    content = content.replace(/authController\.userProfile\.value\?\.signatureImage/g, "authController.userSignature.value");
    content = content.replace(/authController\.userProfile\.value\?\.name/g, "authController.userName.value");
  }

  fs.writeFileSync(file, content);
};

fixSignature('lib/features/invoices/templates/minimalist_template.dart');
fixSignature('lib/features/quotations/templates/minimalist_template.dart');
