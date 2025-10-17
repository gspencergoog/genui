// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import express from 'express';
import { a2aApp } from './a2a';

const port = process.env.PORT || 10002;
const app = express();

// Mount the A2A routes
app.use(a2aApp);

app.listen(port, () => {
  console.log(`🚀 A2A Server started on http://localhost:${port}`);
});
