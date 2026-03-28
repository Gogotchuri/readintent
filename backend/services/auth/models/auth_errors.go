package authmodels

import (
	"errors"

	kratos "github.com/ory/kratos-client-go/v25"
)

// SessionInactiveError is returned when a session has expired.
type SessionInactiveError struct {
	Message string
}

func (e *SessionInactiveError) Error() string {
	return e.Message
}

type AuthUIError struct {
	Message       string              `json:"message"`
	GeneralErrors []string            `json:"general_errors"`
	FieldErrors   map[string][]string `json:"field_errors"`
}

func (ke *AuthUIError) Error() string {
	return ke.Message
}

func ParseAuthUIErrorsFromKratos(err error) *AuthUIError {
	var e AuthUIError
	e.FieldErrors = make(map[string][]string)
	if genericErr, ok := errors.AsType[*kratos.GenericOpenAPIError](err); ok {
		e.Message = genericErr.Error()
		if m, ok := genericErr.Model().(kratos.RegistrationFlow); ok {
			// Get general error message if it exists
			e.GeneralErrors = uiTextErrorsToStrings(m.Ui.GetMessages())
			// Try to find errors in the returned UI
			for _, node := range m.Ui.Nodes {
				if node.Attributes.UiNodeInputAttributes == nil {
					continue
				}
				messages := uiTextErrorsToStrings(node.Messages)
				if len(messages) == 0 {
					continue
				}
				fieldName := node.Attributes.UiNodeInputAttributes.Name
				e.FieldErrors[fieldName] = messages
			}
		} else if m, ok := genericErr.Model().(kratos.LoginFlow); ok {
			// Get general error message if it exists
			e.GeneralErrors = uiTextErrorsToStrings(m.Ui.GetMessages())
			// Try to find errors in the returned UI
			for _, node := range m.Ui.Nodes {
				if node.Attributes.UiNodeInputAttributes == nil {
					continue
				}
				messages := uiTextErrorsToStrings(node.Messages)
				if len(messages) == 0 {
					continue
				}
				fieldName := node.Attributes.UiNodeInputAttributes.Name
				e.FieldErrors[fieldName] = messages
			}
		}
	} else {
		e.Message = err.Error()
	}
	return &e
}

func uiTextErrorsToStrings(uiText []kratos.UiText) []string {
	uiTextStrings := make([]string, len(uiText))
	for i, uiText := range uiText {
		if uiText.Type != "error" {
			continue
		}
		uiTextStrings[i] = uiText.Text
	}
	return uiTextStrings
}
