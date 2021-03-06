//
//  EditViewController.swift
//  notebook
//
//  Created by Павел Кошара on 25/03/2018.
//  Copyright © 2018 user. All rights reserved.
//

import UIKit

private let datePickerHeight: CGFloat = 150
private let minContentTextViewHeight: CGFloat = 115
private let defaultBottomSpacing: CGFloat = 80

@objc protocol EditViewControllerDelegate : class {
    @objc optional func showColorPicker()
}

class EditViewController: UIViewController {
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var noteTitleTextField: UITextField!
    @IBOutlet private weak var noteContentTextView: UITextView!
    @IBOutlet private weak var noteContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var destroyDateSwitch: UISwitch!
    @IBOutlet private weak var destroyDatePicker: UIDatePicker!
    @IBOutlet private weak var datePickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var datePickerAlignConstraint: NSLayoutConstraint!
    @IBOutlet private weak var paletteColorButton: PaletteColorButton!
    @IBOutlet weak var colorsStackView: UIStackView!
    @IBOutlet private var colorButtons: [ColorButton]!
    @IBOutlet weak var bottomSpacingConstraint: NSLayoutConstraint!
    
    public weak var delegate: EditViewControllerDelegate? = nil
    
    private var keyboardHeight: CGFloat = -1
    private var model: Note?
    private var colorPickerState: ColorPickerState?
    
    @IBAction func useDestroyDateDidChange() {
        UIView.animate(withDuration: 0.2) {
            self.datePickerHeightConstraint.constant = self.destroyDateSwitch.isOn ? datePickerHeight : 0
            self.datePickerAlignConstraint.constant = self.destroyDateSwitch.isOn ? 0 : datePickerHeight / 2
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func colorDidTap(_ sender: ColorButton) {
        if sender.color == nil {
            return
        }
        
        colorButtons.forEach { $0.isSelectedColor = false }
        sender.isSelectedColor = true
    }
    
    @IBAction func longPressLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ColorPickerViewController") as? ColorPickerViewController else {
                return
            }
            
            viewController.delegate = self
            viewController.transitioningDelegate = self
            viewController.modalPresentationStyle = .overCurrentContext
            if let state = colorPickerState {
                viewController.state = state
            }
            
            present(viewController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: .UIKeyboardWillShow,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: .UIKeyboardWillHide,
            object: nil)
        
        noteContentTextView.delegate = self
        noteContentTextView.isScrollEnabled = false
        noteTitleTextField.delegate = self
        
        if let model = model {
            noteTitleTextField.text = model.title
            noteContentTextView.text = model.content
            if let destroyDate = model.destroyDate {
                destroyDateSwitch.isOn = true
                destroyDatePicker.date = destroyDate
            }
            if let selectedButton = colorButtons.first(
                where: { $0.color?.isEqual(model.color) ?? false }) {
                selectedButton.isSelectedColor = true
            } else {
                paletteColorButton.color = model.color
                paletteColorButton.isSelectedColor = true
                colorPickerState = ColorPickerState(color: model.color)
            }
        } else {
            colorButtons[0].isSelectedColor = true
        }
        
        datePickerHeightConstraint.constant = destroyDateSwitch.isOn ? datePickerHeight : 0
        datePickerAlignConstraint.constant = destroyDateSwitch.isOn ? 0 : datePickerHeight / 2
        
        resizeContent()
    }
    
    public func getNote() -> Note? {
        guard let title = noteTitleTextField.text,
            let content = noteContentTextView.text,
            let color = colorButtons.first(where: { $0.isSelectedColor })?.color else {
                return nil
        }
        
        if let note = model {
            return Note(
                uid: note.uid,
                title: title,
                content: content,
                color: color,
                importance: note.importance,
                destroyDate: destroyDateSwitch.isOn ? destroyDatePicker.date : nil)
        } else {
            return Note(
                title: title,
                content: content,
                color: color,
                importance: Importance.common,
                destroyDate: destroyDateSwitch.isOn ? destroyDatePicker.date : nil)
        }
    }
    
    public func setNote(_ note: Note) {
        model = note
    }
    
    private func resizeContent() {
        let originalSize = noteContentTextView.frame.size
        let fittingSize = noteContentTextView.sizeThatFits(noteContentTextView.frame.size)
        
        noteContentHeightConstraint.constant = max(fittingSize.height, minContentTextViewHeight)
        if keyboardHeight != -1 {
            let newHeightOffset = noteContentTextView.frame.maxY - (scrollView.bounds.height - keyboardHeight) + fittingSize.height - originalSize.height
            if newHeightOffset < scrollView.contentOffset.y {
                return
            }
            scrollView.contentOffset = CGPoint(x: 0, y: newHeightOffset)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            bottomSpacingConstraint.constant -= keyboardSize.height
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            bottomSpacingConstraint.constant += keyboardSize.height
        }
    }
}

extension EditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        noteTitleTextField.endEditing(true)
        return false
    }
}

extension EditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        resizeContent()
    }
}

extension EditViewController: ColorPickerViewControllerDelegate {
    func didDismiss(state: ColorPickerState) {
        colorPickerState = state
        colorButtons.forEach { $0.isSelectedColor = false }
        paletteColorButton.color = state.selectedColor
        paletteColorButton.isSelectedColor = true
    }
}

extension EditViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ColorPickerTransition(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ColorPickerTransition(isPresenting: false)
    }
}
