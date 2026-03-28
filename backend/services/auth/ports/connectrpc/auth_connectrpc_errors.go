package authconnectrpc

import (
	"errors"

	"connectrpc.com/connect"
	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
	"google.golang.org/genproto/googleapis/rpc/errdetails"
)

func fieldViolationsFromAuthUIError(err *authmodels.AuthUIError) *errdetails.BadRequest {
	var fieldViolations []*errdetails.BadRequest_FieldViolation
	for field, messages := range err.FieldErrors {
		for _, message := range messages {
			fieldViolations = append(fieldViolations, &errdetails.BadRequest_FieldViolation{
				Field:       field,
				Description: message,
			})
		}
	}
	for _, message := range err.GeneralErrors {
		fieldViolations = append(fieldViolations, &errdetails.BadRequest_FieldViolation{
			Field:       "general",
			Description: message,
		})
	}
	return &errdetails.BadRequest{
		FieldViolations: fieldViolations,
	}

}

func newConnectError(code connect.Code, err error) error {
	connectErr := connect.NewError(code, err)
	if authUiErr, ok := errors.AsType[*authmodels.AuthUIError](err); ok {
		if details, detailsErr := connect.NewErrorDetail(fieldViolationsFromAuthUIError(authUiErr)); detailsErr == nil {
			connectErr.AddDetail(details)
		}
	}
	return connectErr
}
