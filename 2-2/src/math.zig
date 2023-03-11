pub const Error = error {
    IntegerOverflow
};

pub fn mulWithOverflow(a: anytype, b: anytype) Error!@TypeOf(a, b) {
    const tuple = @mulWithOverflow(a, b);
    if (tuple[1] != 0) return error.IntegerOverflow;
    return tuple[0];
}

pub fn addWithOverflow(a: anytype, b: anytype) Error!@TypeOf(a, b) {
    const tuple = @addWithOverflow(a, b);
    if (tuple[1] != 0) return error.IntegerOverflow;
    return tuple[0];
}