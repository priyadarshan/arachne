(in-package :arachne.selector)

(defclass <selector> ()
  ((text :reader text
         :initarg :text
         :type string)
   (response :reader response
             :initarg :response
             :type arachne.http:<request>)
   (plump-document :accessor plump-document
                   :type plump:node)
   (cxml-document :accessor cxml-document
                  :type cxml-stp:document)))

(define-condition <empty-selector> (arachne.condition:<arachne-condition>)
  ()
  (:report
   (lambda (condition stream)
     (declare (ignore condition))
     (format stream "Can't create a selector without a text or response."))))

(defmethod initialize-instance :after ((selector <selector>) &key)
  (let ((text
          (if (slot-boundp selector 'text)
              (text selector)
              (if (slot-boundp selector 'response)
                  (arachne.http:response-body (response selector))
                  (error '<empty-selector>)))))
    (setf (plump-document selector) (plump:parse text))
    ;; Because CXML is far less lenient than Plump, we serialize the Plump
    ;; document and parse that with CXML
    (setf (cxml-document selector)
          (cxml:parse
           (with-output-to-string (str)
             (plump:serialize (plump-document selector) str))
           (stp:make-builder)))))

(defmethod css ((selector <selector>) css-selector)
  (clss:select css-selector (plump-document selector)))

(defmethod xpath ((selector <selector>) xpath-selector)
  (xpath:evaluate xpath-selector (cxml-document selector)))