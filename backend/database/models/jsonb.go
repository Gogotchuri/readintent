package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
)

// JSONB models postgres jsonb type
// Convenience for encoding and decoding with sqlx
type JSONB[T any] struct {
	Data  T
	Valid bool
}

func NewJSONB[T any](data T) JSONB[T] {
	if data == nil {
		return JSONB[T]{}
	}
	return JSONB[T]{Data: data, Valid: true}
}

// Implementing Scan/Value interface

func (j *JSONB[T]) Value() (driver.Value, error) {
	if !j.Valid {
		return nil, nil
	}
	return j.Data, nil
}

func (j *JSONB[T]) Scan(src any) error {
	if src == nil {
		return nil
	}
	b, ok := src.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan JSONB: expected []byte, got %T", src)
	}

	return json.Unmarshal(b, &j.Data)
}
