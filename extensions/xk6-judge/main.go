package judge

import (
	"math/rand"

	"go.k6.io/k6/v2/js/modules"
)

func init() {
	modules.Register("k6/x/judge", new(Judge))
}

type Judge struct{}

// Score returns a random score between 1 and 10 for the given pizza name.
func (j *Judge) Score(name string) int {
	return rand.Intn(10) + 1
}
