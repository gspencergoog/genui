use flutter_rust_bridge::frb;
use std::sync::{Arc, Mutex};
use automerge::sync::State;
use automerge::sync::SyncDoc;
use crate::api::doc::DocHandle;

#[frb(opaque)]
pub struct SyncStateHandle {
    pub(crate) inner: Arc<Mutex<State>>,
}

impl SyncStateHandle {
    pub fn create() -> Self {
        Self {
            inner: Arc::new(Mutex::new(State::new())),
        }
    }

    pub fn decode_message(message: Vec<u8>) -> anyhow::Result<()> {
        let _ = automerge::sync::Message::decode(&message).map_err(|e| anyhow::anyhow!(e))?;
        Ok(())
    }
}

pub fn generate_sync_message(doc: &DocHandle, sync_state: &SyncStateHandle) -> anyhow::Result<Option<Vec<u8>>> {
    let doc_guard = doc.inner.lock().unwrap();
    let mut sync_guard = sync_state.inner.lock().unwrap();
    let msg = doc_guard.generate_sync_message(&mut *sync_guard);
    Ok(msg.map(|m| m.encode()))
}

pub fn receive_sync_message(doc: &DocHandle, sync_state: &SyncStateHandle, message: Vec<u8>) -> anyhow::Result<()> {
    let mut doc_guard = doc.inner.lock().unwrap();
    let mut sync_guard = sync_state.inner.lock().unwrap();
    let decoded_msg = automerge::sync::Message::decode(&message).map_err(|e| anyhow::anyhow!(e))?;
    doc_guard.receive_sync_message(&mut *sync_guard, decoded_msg).map_err(|e| anyhow::anyhow!(e))?;
    Ok(())
}
