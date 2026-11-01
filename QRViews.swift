import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

// MARK: - QR payload

struct ScannedPayee: Identifiable, Hashable {
    let phone: String
    let name: String
    var id: String { phone }
}

enum QRCodec {
    static func payload(phone: String, name: String) -> String {
        var components = URLComponents()
        components.scheme = "pakpay"
        components.host = "pay"
        components.queryItems = [
            URLQueryItem(name: "phone", value: phone),
            URLQueryItem(name: "name", value: name)
        ]
        return components.string ?? ""
    }

    static func parse(_ text: String) -> ScannedPayee? {
        guard let components = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme == "pakpay",
              let phone = components.queryItems?.first(where: { $0.name == "phone" })?.value,
              Validators.isValidPhone(phone) else { return nil }
        let name = components.queryItems?.first(where: { $0.name == "name" })?.value ?? ""
        return ScannedPayee(phone: phone, name: name)
    }

    static func image(for text: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        let context = CIContext()
        if let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
           let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// MARK: - My QR

struct MyQRView: View {
    @EnvironmentObject var store: AppStore

    private var payload: String {
        QRCodec.payload(phone: store.account?.phone ?? "", name: store.account?.name ?? "")
    }

    var body: some View {
        let image = QRCodec.image(for: payload)
        ScrollView {
            VStack(spacing: 16) {
                Text(store.account?.name ?? "").font(.title2.bold())
                Text(store.account?.phone ?? "").foregroundStyle(Color.secondary)

                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("Ye QR dusre Pak Transfer user se scan karwayein, wo seedha aapko paisay bhej sakega.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)

                ShareLink(item: Image(uiImage: image),
                          preview: SharePreview("Pak Transfer QR", image: Image(uiImage: image))) {
                    Label("QR share karein", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand.opacity(0.12))
                        .foregroundStyle(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My QR")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Scan QR

struct ScanQRView: View {
    @State private var payee: ScannedPayee?
    @State private var errorMessage: String?
    @State private var manualText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                QRScannerView { code in handle(code) }
                    .frame(height: 360)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("QR ko camera ke saamne rakhein")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Camera na chale to QR ka text paste karein")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                    HStack {
                        TextField("pakpay://pay?phone=...", text: $manualText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button("Use") { handle(manualText) }
                            .buttonStyle(.borderedProminent)
                            .disabled(manualText.isEmpty)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Scan QR")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $payee) { found in
            SendMoneyView(phone: found.phone, name: found.name)
        }
        .alert("Scan nahi hua", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func handle(_ code: String) {
        if let found = QRCodec.parse(code) {
            payee = found
        } else {
            errorMessage = "Ye Pak Transfer ka QR nahi hai."
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = onCode
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.onCode = onCode
    }
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var handled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handled = false
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            if !session.isRunning { session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            if session.isRunning { session.stopRunning() }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !handled,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        handled = true
        onCode?(value)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.handled = false
        }
    }
}
