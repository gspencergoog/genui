// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { a2aApp } from './a2a';
import cors from 'cors';
import express from 'express';

const port = process.env.PORT || 10002;

a2aApp.use(cors());
a2aApp.use(express.json());

a2aApp.listen(port, () => {
  console.log(`🚀 A2A Server started on http://localhost:${port}`);
});
