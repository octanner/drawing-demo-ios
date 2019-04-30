/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The primary view controller.
*/

import UIKit

class CanvasMainViewController: UIViewController {

    enum ColorType {
        case black
        case red
        case blue
        
        var color: UIColor {
            switch self {
            case .black:
                return .darkBlack
            case .red:
                return .darkRed
            case .blue:
                return .darkBlue
            }
        }
    }
    
    var cgView: StrokeCGView!

    var fingerStrokeRecognizer: StrokeGestureRecognizer!
    var pencilStrokeRecognizer: StrokeGestureRecognizer!

    @IBOutlet var pencilButton: UIButton!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet weak var upDownButton: UIButton!
    @IBOutlet var palletView: UIView!
    
    @IBOutlet weak var blackColorButton: UIButton!
    @IBOutlet weak var redColorButton: UIButton!
    @IBOutlet weak var blueColorButton: UIButton!
    @IBOutlet weak var sizeView: UIView!
    @IBOutlet weak var sizeSlider: UISlider!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    
    var strokeCollection = StrokeCollection()
    var canvasContainerView: CanvasContainerView!

    var undidStrokes = [Stroke]()
    var previousColor = ColorType.black
    var currentColor = ColorType.black {
        didSet {
            guard currentColor != oldValue else { return }
            previousColor = oldValue
            fingerStrokeRecognizer.color = currentColor.color.cgColor
            pencilStrokeRecognizer.color = currentColor.color.cgColor
            updateColorButtons()
        }
    }
    private var previousStrokeWidth: CGFloat = 1
    private var writtenWidth: CGFloat = 0.5 {
        didSet {
            guard writtenWidth != oldValue else { return }
            previousStrokeWidth = oldValue
        }
    }
    private var currentStrokeWidth: CGFloat = 0.5 {
        didSet {
            fingerStrokeRecognizer.lineWidth = currentStrokeWidth
            pencilStrokeRecognizer.lineWidth = currentStrokeWidth
            updateSizeView()
        }
    }
    private var palletIsCollapsed = false {
        didSet {
            guard palletIsCollapsed != oldValue else { return }
            updatePallet()
        }
    }
    
    
    /// Prepare the drawing canvas.
    /// - Tag: CanvasMainViewController-viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItems = [cancelButton]
        setUpColorButtons()
        let screenBounds = UIScreen.main.bounds
        let maxScreenDimension = max(screenBounds.width, screenBounds.height)

        let cgView = StrokeCGView(frame: CGRect(origin: .zero, size: CGSize(width: maxScreenDimension, height: maxScreenDimension)))
        cgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.cgView = cgView
        
        let canvasContainerView = CanvasContainerView(canvasSize: cgView.frame.size)
        canvasContainerView.documentView = cgView
        self.canvasContainerView = canvasContainerView
        scrollView.contentSize = canvasContainerView.frame.size
        scrollView.contentOffset = CGPoint(x: (canvasContainerView.frame.width - scrollView.bounds.width) / 2.0,
                                           y: (canvasContainerView.frame.height - scrollView.bounds.height) / 2.0)
        scrollView.addSubview(canvasContainerView)
        scrollView.backgroundColor = canvasContainerView.backgroundColor
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 0.5
        scrollView.panGestureRecognizer.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
        scrollView.pinchGestureRecognizer?.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
        // We put our UI elements on top of the scroll view, so we don't want any of the
        // delay or cancel machinery in place.
        scrollView.delaysContentTouches = false

        self.fingerStrokeRecognizer = setupStrokeGestureRecognizer(isForPencil: false)
        self.pencilStrokeRecognizer = setupStrokeGestureRecognizer(isForPencil: true)

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        view.addInteraction(pencilInteraction)

        setupPencilUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.flashScrollIndicators()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// A helper method that creates stroke gesture recognizers.
    /// - Tag: setupStrokeGestureRecognizer
    func setupStrokeGestureRecognizer(isForPencil: Bool) -> StrokeGestureRecognizer {
        let recognizer = StrokeGestureRecognizer(target: self, action: #selector(strokeUpdated(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(recognizer)
        recognizer.coordinateSpaceView = cgView
        recognizer.isForPencil = isForPencil
        return recognizer
    }
    
    func receivedAllUpdatesForStroke(_ stroke: Stroke) {
        cgView.setNeedsDisplay(for: stroke)
        stroke.clearUpdateInfo()
    }
    
    var canvasIsBlank = true {
        didSet {
            guard canvasIsBlank != oldValue else { return }
            navigationItem.leftBarButtonItems = canvasIsBlank ? [cancelButton] : [cancelButton, saveButton]
        }
    }

    @IBAction func clearButtonAction(_ sender: AnyObject) {
        self.strokeCollection = StrokeCollection()
        cgView.strokeCollection = self.strokeCollection
        canvasIsBlank = true
        undidStrokes = []
        updateUndoRedoButtons()
    }

    /// Handles the gesture for `StrokeGestureRecognizer`.
    /// - Tag: strokeUpdate
    @objc
    func strokeUpdated(_ strokeGesture: StrokeGestureRecognizer) {
        if strokeGesture === pencilStrokeRecognizer {
            lastSeenPencilInteraction = Date()
        }
        
        var stroke: Stroke?
        if strokeGesture.state != .cancelled {
            stroke = strokeGesture.stroke
            if strokeGesture.state == .began ||
               (strokeGesture.state == .ended && strokeCollection.activeStroke == nil) {
                strokeCollection.activeStroke = stroke
            }
        } else {
            strokeCollection.activeStroke = nil
        }
        
        if let stroke = stroke {
            if strokeGesture.state == .ended {
                if strokeGesture === pencilStrokeRecognizer {
                    // Make sure we get the final stroke update if needed.
                    stroke.receivedAllNeededUpdatesBlock = { [weak self] in
                        self?.receivedAllUpdatesForStroke(stroke)
                    }
                }
               strokeCollection.takeActiveStroke()
            }
        }

        cgView.strokeCollection = strokeCollection
        canvasIsBlank = strokeCollection.strokes.isEmpty
        writtenWidth = currentStrokeWidth
        updateUndoRedoButtons()
    }

    // MARK: Pencil Recognition and UI Adjustments
    /*
         Since usage of the Apple Pencil can be very temporary, the best way to
         actually check for it being in use is to remember the last interaction.
         Also make sure to provide an escape hatch if you modify your UI for
         times when the pencil is in use vs. not.
     */

    // Timeout the pencil mode if no pencil has been seen for 5 minutes and the app is brought back in foreground.
    let pencilResetInterval = TimeInterval(60.0 * 5)

    var lastSeenPencilInteraction: Date? {
        didSet {
            if lastSeenPencilInteraction != nil && !pencilMode {
                pencilMode = true
            }
        }
    }

    func shouldTimeoutPencilMode() -> Bool {
        guard let lastSeenPencilInteraction = self.lastSeenPencilInteraction else { return true }
        return abs(lastSeenPencilInteraction.timeIntervalSinceNow) > self.pencilResetInterval
    }
    
    private func setupPencilUI() {
        self.pencilMode = false

        self.willEnterForegroundNotification = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: UIApplication.shared,
            queue: nil) { [unowned self](_) in
                if self.pencilMode && self.shouldTimeoutPencilMode() {
                    self.stopPencilButtonAction(nil)
                }
        }
    }

    var willEnterForegroundNotification: NSObjectProtocol?

    /// Toggles pencil mode for the app.
    /// - Tag: pencilMode
    var pencilMode = false {
        didSet {
            if pencilMode {
                scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
                pencilButton.isHidden = false
                if let view = fingerStrokeRecognizer.view {
                    view.removeGestureRecognizer(fingerStrokeRecognizer)
                }
            } else {
                scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
                pencilButton.isHidden = true
                if fingerStrokeRecognizer.view == nil {
                    scrollView.addGestureRecognizer(fingerStrokeRecognizer)
                }
            }
        }
    }
    
    @IBAction func stopPencilButtonAction(_ sender: AnyObject?) {
        lastSeenPencilInteraction = nil
        pencilMode = false
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func palletButtonPressed() {
        palletIsCollapsed.toggle()
    }
    
    @IBAction func save(_ sender: Any) {
        let image = canvasContainerView.canvasView.asImage
        guard let data = image.pngData() else { return }
        CoreDataManager.shared.addDrawing(data: data)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func blackColorPressed() {
        currentColor = .black
    }

    @IBAction func redColorPressed() {
        currentColor = .red
    }

    @IBAction func blueColorPressed() {
        currentColor = .blue
    }
    
    @IBAction func slid(_ sender: UISlider) {
        currentStrokeWidth = CGFloat(sender.value)
    }
    
    @IBAction func undoPressed(_ sender: Any) {
        guard !strokeCollection.strokes.isEmpty else { return }
        let deletedStroke = strokeCollection.strokes.removeLast()
        undidStrokes.append(deletedStroke)
        cgView.strokeCollection = strokeCollection
        cgView.setNeedsDisplay()
        updateUndoRedoButtons()
    }
    
    @IBAction func redoPressed(_ sender: Any) {
        guard let redidStroke = undidStrokes.last else { return }
        strokeCollection.strokes.append(redidStroke)
        undidStrokes.removeLast()
        cgView.strokeCollection = strokeCollection
        cgView.setNeedsDisplay()
        updateUndoRedoButtons()
    }
    
    func updateUndoRedoButtons() {
        canvasIsBlank = strokeCollection.strokes.isEmpty
        undoButton.isEnabled = !canvasIsBlank
        redoButton.isEnabled = !undidStrokes.isEmpty
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension CanvasMainViewController: UIGestureRecognizerDelegate {

    // We want the pencil to recognize simultaniously with all others.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === pencilStrokeRecognizer {
            return otherGestureRecognizer !== fingerStrokeRecognizer
        }

        return false
    }

}

// MARK: - UIScrollViewDelegate

extension CanvasMainViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.canvasContainerView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        var desiredScale = self.traitCollection.displayScale
        let existingScale = cgView.contentScaleFactor
        
        if scale >= 2.0 {
            desiredScale *= 2.0
        }
        
        if abs(desiredScale - existingScale) > 0.000_01 {
            cgView.contentScaleFactor = desiredScale
            cgView.setNeedsDisplay()
        }
    }
}

// MARK: - UIPencilInteractionDelegate

@available(iOS 12.1, *)
extension CanvasMainViewController: UIPencilInteractionDelegate {

    /// Handles double taps that the user makes on an Apple Pencil.
    /// - Tag: pencilInteractionDidTap
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        switch UIPencilInteraction.preferredTapAction {
        case .showColorPalette:
            palletIsCollapsed.toggle()
        case .switchPrevious:
            palletIsCollapsed = false
            switchToPrevious()
        default:
            break
        }
    }

}

// Private

private extension CanvasMainViewController {
    
    func setUpColorButtons() {
        blackColorButton.backgroundColor = ColorType.black.color
        redColorButton.backgroundColor = ColorType.red.color
        blueColorButton.backgroundColor = ColorType.blue.color
        sizeView.backgroundColor = currentColor.color
        
        blackColorButton.layer.cornerRadius = blackColorButton.frame.height / 2
        redColorButton.layer.cornerRadius = redColorButton.frame.height / 2
        blueColorButton.layer.cornerRadius = blueColorButton.frame.height / 2
        blueColorButton.layer.cornerRadius = blueColorButton.frame.height / 2
        sizeView.layer.cornerRadius = sizeView.frame.size.height / 2
        updateColorButtons()
    }
    
    func updateColorButtons() {
        let selectedTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        blackColorButton.transform = currentColor == .black ? selectedTransform : .identity
        redColorButton.transform = currentColor == .red ? selectedTransform : .identity
        blueColorButton.transform = currentColor == .blue ? selectedTransform : .identity
        sizeView.backgroundColor = currentColor.color
    }
    
    func updatePallet() {
        UIView.animate(withDuration: 0.25) {
            let arrowTransform = self.palletIsCollapsed ? CGAffineTransform(rotationAngle: CGFloat.pi + 0.01) : .identity
            self.upDownButton.imageView?.transform = arrowTransform
            self.palletView.isHidden = self.palletIsCollapsed
        }
    }
    
    func updateSizeView() {
        let scale = currentStrokeWidth * 1.5
        sizeView.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        if sizeSlider.value != Float(currentStrokeWidth) {
            sizeSlider.setValue(Float(currentStrokeWidth), animated: true)
        }
    }
    
    func switchToPrevious() {
        currentColor = previousColor
        currentStrokeWidth = previousStrokeWidth
    }
    
}
