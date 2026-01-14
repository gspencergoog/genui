use flutter_rust_bridge::frb;
use std::sync::{Arc, Mutex};
use automerge::{Automerge, ReadDoc, transaction::Transactable};
use autosurgeon::{Hydrate, Reconcile};
use std::collections::HashMap;

#[frb(opaque)]
#[derive(Clone)]
pub struct DocHandle {
    pub(crate) inner: Arc<Mutex<Automerge>>,
}

#[derive(Debug, Clone, Reconcile, Hydrate)]
pub enum JsonAuto {
    Null,
    Bool(bool),
    Int(i64),
    Uint(u64),
    Float(f64),
    String(String),
    Array(Vec<JsonAuto>),
    Map(HashMap<String, JsonAuto>),
}

impl From<serde_json::Value> for JsonAuto {
    fn from(v: serde_json::Value) -> Self {
        match v {
            serde_json::Value::Null => JsonAuto::Null,
            serde_json::Value::Bool(b) => JsonAuto::Bool(b),
            serde_json::Value::Number(n) => {
                if let Some(i) = n.as_i64() {
                    JsonAuto::Int(i)
                } else if let Some(u) = n.as_u64() {
                    JsonAuto::Uint(u)
                } else if let Some(f) = n.as_f64() {
                    JsonAuto::Float(f)
                } else {
                    JsonAuto::Null
                }
            }
            serde_json::Value::String(s) => JsonAuto::String(s),
            serde_json::Value::Array(a) => {
                JsonAuto::Array(a.into_iter().map(JsonAuto::from).collect())
            }
            serde_json::Value::Object(m) => {
                JsonAuto::Map(m.into_iter().map(|(k, v)| (k, JsonAuto::from(v))).collect())
            }
        }
    }
}

impl From<JsonAuto> for serde_json::Value {
    fn from(v: JsonAuto) -> Self {
        match v {
            JsonAuto::Null => serde_json::Value::Null,
            JsonAuto::Bool(b) => serde_json::Value::Bool(b),
            JsonAuto::Int(i) => serde_json::Value::Number(i.into()),
            JsonAuto::Uint(u) => serde_json::Value::Number(u.into()),
            JsonAuto::Float(f) => {
                serde_json::Number::from_f64(f).map(serde_json::Value::Number).unwrap_or(serde_json::Value::Null)
            }
            JsonAuto::String(s) => serde_json::Value::String(s),
            JsonAuto::Array(a) => {
                serde_json::Value::Array(a.into_iter().map(serde_json::Value::from).collect())
            }
            JsonAuto::Map(m) => serde_json::Value::Object(
                m.into_iter().map(|(k, v)| (k, serde_json::Value::from(v))).collect(),
            ),
        }
    }
}

impl DocHandle {
    pub fn new() -> Self {
        Self {
            inner: Arc::new(Mutex::new(Automerge::new())),
        }
    }

    pub fn load(bytes: Vec<u8>) -> anyhow::Result<Self> {
        let doc = Automerge::load(&bytes).map_err(|e| anyhow::anyhow!(e))?;
        Ok(Self {
            inner: Arc::new(Mutex::new(doc)),
        })
    }

    pub fn save(&self) -> anyhow::Result<Vec<u8>> {
        let doc = self.inner.lock().unwrap();
        Ok(doc.save())
    }

    pub fn reconcile_json(&self, json_str: String) -> anyhow::Result<()> {
        let mut doc = self.inner.lock().unwrap();
        let val: serde_json::Value = serde_json::from_str(&json_str)?;

        // Ensure root is an Object
        let map_val = match val {
             serde_json::Value::Object(m) => m,
             _ => return Err(anyhow::anyhow!("Root JSON must be an object")),
        };

        let auto_map: HashMap<String, JsonAuto> = map_val.into_iter().map(|(k, v)| (k, JsonAuto::from(v))).collect();
        let mut txn = doc.transaction();
        autosurgeon::reconcile(&mut txn, &auto_map).map_err(|e| anyhow::anyhow!(e))?;
        txn.commit();
        Ok(())
    }

    pub fn hydrate_json(&self) -> anyhow::Result<String> {
        let doc = self.inner.lock().unwrap();
        let auto_map: HashMap<String, JsonAuto> = autosurgeon::hydrate(&*doc).map_err(|e| anyhow::anyhow!(e))?;

        let json_map: serde_json::Map<String, serde_json::Value> = auto_map.into_iter().map(|(k, v)| (k, serde_json::Value::from(v))).collect();
        let val = serde_json::Value::Object(json_map);

        Ok(val.to_string())
    }

    pub fn fork(&self) -> Self {
        let doc = self.inner.lock().unwrap();
        Self {
            inner: Arc::new(Mutex::new(doc.fork())),
        }
    }

    pub fn merge(&self, other: &DocHandle) -> anyhow::Result<()> {
        let mut doc = self.inner.lock().unwrap();
        let mut other_doc = other.inner.lock().unwrap();
        doc.merge(&mut other_doc).map_err(|e| anyhow::anyhow!(e))?;
        Ok(())
    }
}
