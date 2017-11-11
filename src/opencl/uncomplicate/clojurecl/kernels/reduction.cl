#ifndef ACCUMULATOR
    #define ACCUMULATOR double
#endif

#ifndef WGS
#define WGS 256
#endif

#ifndef WGSm
#define WGSm 16
#endif

#ifndef WGSn
#define WGSn 16
#endif

// ================= Sum reduction =============================================

inline ACCUMULATOR work_group_reduction_sum (const ACCUMULATOR value) {

    uint local_id = get_local_id(0);

    __local ACCUMULATOR lacc[WGS];
    lacc[local_id] = value;

    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    ACCUMULATOR pacc = value;
    uint i = get_local_size(0);
    while (i > 0) {
        bool include_odd = (i > ((i >> 1) << 1)) && (local_id == ((i >> 1) - 1));
        i >>= 1;
        if (include_odd) {
            pacc += lacc[local_id + i + 1];
        }
        if (local_id < i) {
            pacc += lacc[local_id + i];
            lacc[local_id] = pacc;
        }
        work_group_barrier(CLK_LOCAL_MEM_FENCE);
    }

    return lacc[0];
}

inline ACCUMULATOR work_group_reduction_sum_2 (const uint orientation, const REAL value) {

    uint local_row = get_local_id(1 - orientation);
    uint local_col = get_local_id(orientation);
    uint local_m = get_local_size(1 - orientation);

    __local ACCUMULATOR lacc[WGSm * WGSn];
    lacc[local_row + local_col * local_m] = value;

    work_group_barrier(CLK_LOCAL_MEM_FENCE);

    ACCUMULATOR pacc = value;
    uint i = get_local_size(orientation);
    while (i > 0) {
        bool include_odd = (i > ((i >> 1) << 1)) && (local_col == ((i >> 1) - 1));
        i >>= 1;
        if (include_odd) {
            pacc += lacc[local_row + (local_col + i + 1) * local_m];
        }
        if (local_col < i) {
            pacc += lacc[local_row + (local_col + i) * local_m];
            lacc[local_row + local_col * local_m] = pacc;
        }
        work_group_barrier(CLK_LOCAL_MEM_FENCE);
    }

    return lacc[local_row];

}
