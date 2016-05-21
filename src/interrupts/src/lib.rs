#![feature(const_fn)]
#![no_std]

extern {
    fn load_idt(idt: *const IdtPointer);
}

#[derive(Copy,Clone)]
#[repr(packed,C)]
struct IdtEntry {
    base_low: u16,
    selector: u16,
    zero: u8,
    flags: u8,
    base_mid: u16,
    base_high: u32,
    reserved: u32,
}

#[repr(packed,C)]
struct IdtPointer {
    limit: u16,
    base: u64,
}

struct Idt {
    entries: [IdtEntry; 256],
}

impl Idt {
    const fn new() -> Idt {
        Idt {
            entries: [IdtEntry {
                base_low: 0,
                selector: 0,
                zero: 0,
                flags: 0,
                base_mid: 0,
                base_high: 0,
                reserved: 0,
            }; 256],
        }
    }
}

static mut IDT: Idt = Idt::new();
static mut IDT_POINTER: IdtPointer = IdtPointer { limit: 0, base: 0 };

pub fn install() {
    // Modifying static muts are very unsafe. But we have no concurrency here, so we're not worried
    // about data races.
    unsafe {

        IDT_POINTER.limit = (core::mem::size_of::<IdtEntry>() as u16 * 256) - 1;
        IDT_POINTER.base = &IDT as *const Idt as u64;

        // add ISRs here

        load_idt(&IDT_POINTER as *const IdtPointer);
    }
}
